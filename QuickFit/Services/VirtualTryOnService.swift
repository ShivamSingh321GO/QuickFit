//
//  VirtualTryOnService.swift
//  QuickFit
//

import UIKit
import CoreImage
import Vision

final class VirtualTryOnService {
    static let shared = VirtualTryOnService()
    
    private let hfQueueJoinURL = "https://yisol-idm-vton.hf.space/queue/join"
    private let hfQueueDataURL = "https://yisol-idm-vton.hf.space/queue/data"
    
    private let ciContext = CIContext()
    
    private init() {}
    
    func generateTryOn(modelImage: UIImage, outfitImage: UIImage, clothType: String = "upper") async throws -> UIImage {
        if let result = try? await performHuggingFaceTryOn(modelImage: modelImage, outfitImage: outfitImage) {
            return result
        }
        
        return await performLocalComposite(modelImage: modelImage, outfitImage: outfitImage)
    }
    
    // MARK: - Hugging Face API Integration
    
    private func performHuggingFaceTryOn(modelImage: UIImage, outfitImage: UIImage) async throws -> UIImage? {
        guard let modelData = modelImage.jpegData(compressionQuality: 0.8),
              let outfitData = outfitImage.jpegData(compressionQuality: 0.8) else { return nil }
        
        let sessionHash = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        
        guard let joinURL = URL(string: hfQueueJoinURL) else { return nil }
        var joinReq = URLRequest(url: joinURL)
        joinReq.httpMethod = "POST"
        joinReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let modelDict: [String: Any] = [
            "background": "data:image/jpeg;base64,\(modelData.base64EncodedString())",
            "layers": [],
            "composite": NSNull()
        ]
        
        let outfitDict: [String: Any] = [
            "background": "data:image/jpeg;base64,\(outfitData.base64EncodedString())",
            "layers": [],
            "composite": NSNull()
        ]
        
        let dataPayload: [Any] = [
            modelDict,
            outfitDict,
            "Garment try-on",
            true, // auto-crop
            true, // auto-mask
            30,   // denoising steps
            42    // seed
        ]
        
        let joinBody: [String: Any] = [
            "data": dataPayload,
            "fn_index": 2,
            "session_hash": sessionHash
        ]
        joinReq.httpBody = try JSONSerialization.data(withJSONObject: joinBody)
        
        let (joinData, _) = try await URLSession.shared.data(for: joinReq)
        guard let joinJSON = try? JSONSerialization.jsonObject(with: joinData) as? [String: Any],
              let eventId = joinJSON["event_id"] as? String else {
            return nil
        }
        
        guard let streamURL = URL(string: "\(hfQueueDataURL)?session_hash=\(sessionHash)") else { return nil }
        var streamReq = URLRequest(url: streamURL)
        streamReq.httpMethod = "GET"
        streamReq.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        streamReq.timeoutInterval = 300.0
        
        let (asyncBytes, _) = try await URLSession.shared.bytes(for: streamReq)
        
        for try await line in asyncBytes.lines {
            if line.hasPrefix("data: ") {
                let eventData = line.dropFirst(6)
                if let eventDataObj = eventData.data(using: .utf8),
                   let eventJSON = try? JSONSerialization.jsonObject(with: eventDataObj) as? [String: Any] {
                    
                    let msg = eventJSON["msg"] as? String
                    
                    if msg == "process_completed" {
                        if let output = eventJSON["output"] as? [String: Any],
                           let dataArr = output["data"] as? [[Any]],
                           let firstData = dataArr.first,
                           let imgDict = firstData.first as? [String: Any],
                           let url = imgDict["url"] as? String {
                            return try await downloadImage(from: url)
                        }
                        break
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Shared Helpers
    
    private func downloadImage(from urlString: String) async throws -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    }
    
    // MARK: - Local Fallback
    
    private func performLocalComposite(modelImage: UIImage, outfitImage: UIImage) async -> UIImage {
        let cleanOutfit = await AvatarStylizationService.shared.removeBackground(from: outfitImage)
        guard let modelCG = modelImage.cgImage, let outfitCG = cleanOutfit.cgImage else { return modelImage }
        
        let chinY = await detectChinNormalizedY(in: modelCG)
        let modelCI = CIImage(cgImage: modelCG)
        let outfitCI = CIImage(cgImage: outfitCG)
        
        let targetWidth = modelCI.extent.width * 0.72
        let scale = targetWidth / max(outfitCI.extent.width, 1)
        let tx = (modelCI.extent.width - (outfitCI.extent.width * scale)) / 2.0
        let ty = (modelCI.extent.height * chinY) - (outfitCI.extent.height * scale)
        
        let transform = CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: tx, y: ty))
        let transformedOutfit = outfitCI.transformed(by: transform)
        
        guard let filter = CIFilter(name: "CISourceOverCompositing") else { return modelImage }
        filter.setValue(transformedOutfit, forKey: kCIInputImageKey)
        filter.setValue(modelCI, forKey: kCIInputBackgroundImageKey)
        
        guard let outputCI = filter.outputImage,
              let outputCG = ciContext.createCGImage(outputCI, from: modelCI.extent) else { return modelImage }
        
        return UIImage(cgImage: outputCG, scale: modelImage.scale, orientation: modelImage.imageOrientation)
    }
    
    private func detectChinNormalizedY(in cgImage: CGImage) async -> CGFloat {
        await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { req, _ in
                if let face = (req.results as? [VNFaceObservation])?.first {
                    continuation.resume(returning: max(face.boundingBox.minY - 0.03, 0.35))
                } else {
                    continuation.resume(returning: 0.68)
                }
            }
            try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
    }
}
