//
//  AvatarStylizationService.swift
//  QuickFit
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

final class AvatarStylizationService {
    static let shared = AvatarStylizationService()
    private let ciContext = CIContext()
    
    private init() {}
    
    func removeBackground(from image: UIImage) async -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if #available(iOS 17.0, *) {
                    let request = VNGenerateForegroundInstanceMaskRequest()
                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    do {
                        try handler.perform([request])
                        if let result = request.results?.first {
                            let buffer = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: false)
                            let ciImage = CIImage(cvPixelBuffer: buffer)
                            if let outputCGImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) {
                                let finalImage = UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
                                continuation.resume(returning: finalImage)
                                return
                            }
                        }
                    } catch {
                        print("iOS 17 Foreground Mask fallback to PersonSegmentation: \(error)")
                    }
                }
                
                let request = VNGeneratePersonSegmentationRequest()
                request.qualityLevel = .accurate
                request.outputPixelFormat = kCVPixelFormatType_OneComponent8
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    guard let result = request.results?.first else {
                        continuation.resume(returning: image)
                        return
                    }
                    
                    let maskBuffer = result.pixelBuffer
                    let inputCIImage = CIImage(cgImage: cgImage)
                    var maskCIImage = CIImage(cvPixelBuffer: maskBuffer)
                    
                    let scaleX = inputCIImage.extent.width / maskCIImage.extent.width
                    let scaleY = inputCIImage.extent.height / maskCIImage.extent.height
                    maskCIImage = maskCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                    
                    let filter = CIFilter.blendWithMask()
                    filter.inputImage = inputCIImage
                    
                    let backdropColor = CIColor(red: 0.1, green: 0.12, blue: 0.18, alpha: 1.0)
                    let backdropImage = CIImage(color: backdropColor).cropped(to: inputCIImage.extent)
                    
                    filter.backgroundImage = backdropImage
                    filter.maskImage = maskCIImage
                    
                    guard let outputCIImage = filter.outputImage,
                          let outputCGImage = self.ciContext.createCGImage(outputCIImage, from: inputCIImage.extent) else {
                        continuation.resume(returning: image)
                        return
                    }
                    
                    let finalImage = UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
                    continuation.resume(returning: finalImage)
                } catch {
                    print("Background removal error: \(error)")
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    func applyStyle(_ style: String, to image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let inputCIImage = CIImage(cgImage: cgImage)
        var outputCIImage: CIImage? = inputCIImage
        
        switch style {
        case "Vintage Film":
            if let colorControls = CIFilter(name: "CIColorControls") {
                colorControls.setValue(inputCIImage, forKey: kCIInputImageKey)
                colorControls.setValue(1.15, forKey: kCIInputSaturationKey)
                colorControls.setValue(1.08, forKey: kCIInputContrastKey)
                
                if let temp = CIFilter(name: "CITemperatureAndTint") {
                    temp.setValue(colorControls.outputImage ?? inputCIImage, forKey: kCIInputImageKey)
                    temp.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                    temp.setValue(CIVector(x: 7200, y: 20), forKey: "inputTargetNeutral") // Warm golden tint
                    
                    if let vignette = CIFilter(name: "CIVignette") {
                        vignette.setValue(temp.outputImage ?? inputCIImage, forKey: kCIInputImageKey)
                        vignette.setValue(1.5, forKey: kCIInputRadiusKey)
                        vignette.setValue(0.7, forKey: kCIInputIntensityKey)
                        outputCIImage = vignette.outputImage
                    } else {
                        outputCIImage = temp.outputImage
                    }
                } else {
                    outputCIImage = colorControls.outputImage
                }
            }
            
        case "Cyber Neon":
            if let colorControls = CIFilter(name: "CIColorControls") {
                colorControls.setValue(inputCIImage, forKey: kCIInputImageKey)
                colorControls.setValue(1.7, forKey: kCIInputSaturationKey)
                colorControls.setValue(1.25, forKey: kCIInputContrastKey)
                
                if let bloom = CIFilter(name: "CIBloom") {
                    bloom.setValue(colorControls.outputImage ?? inputCIImage, forKey: kCIInputImageKey)
                    bloom.setValue(12.0, forKey: kCIInputRadiusKey)
                    bloom.setValue(0.6, forKey: kCIInputIntensityKey)
                    outputCIImage = bloom.outputImage
                } else {
                    outputCIImage = colorControls.outputImage
                }
            }
            
        case "Anime Pastel":
            if let shadowAdjust = CIFilter(name: "CIHighlightShadowAdjust") {
                shadowAdjust.setValue(inputCIImage, forKey: kCIInputImageKey)
                shadowAdjust.setValue(0.8, forKey: "inputHighlightAmount") // Soften highlights
                shadowAdjust.setValue(0.3, forKey: "inputShadowAmount")    // Brighten shadows
                
                if let colorControls = CIFilter(name: "CIColorControls") {
                    colorControls.setValue(shadowAdjust.outputImage ?? inputCIImage, forKey: kCIInputImageKey)
                    colorControls.setValue(1.35, forKey: kCIInputSaturationKey)
                    colorControls.setValue(1.05, forKey: kCIInputContrastKey)
                    colorControls.setValue(0.04, forKey: kCIInputBrightnessKey)
                    
                    if let bloom = CIFilter(name: "CIBloom") {
                        bloom.setValue(colorControls.outputImage ?? inputCIImage, forKey: kCIInputImageKey)
                        bloom.setValue(6.0, forKey: kCIInputRadiusKey)
                        bloom.setValue(0.4, forKey: kCIInputIntensityKey)
                        outputCIImage = bloom.outputImage
                    } else {
                        outputCIImage = colorControls.outputImage
                    }
                } else {
                    outputCIImage = shadowAdjust.outputImage
                }
            }
            
        case "Golden Hour":
            if let temp = CIFilter(name: "CITemperatureAndTint") {
                temp.setValue(inputCIImage, forKey: kCIInputImageKey)
                temp.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                temp.setValue(CIVector(x: 7800, y: 50), forKey: "inputTargetNeutral") // Deep golden sunset
                
                if let colorControls = CIFilter(name: "CIColorControls") {
                    colorControls.setValue(temp.outputImage ?? inputCIImage, forKey: kCIInputImageKey)
                    colorControls.setValue(1.3, forKey: kCIInputSaturationKey)
                    colorControls.setValue(1.12, forKey: kCIInputContrastKey)
                    outputCIImage = colorControls.outputImage
                } else {
                    outputCIImage = temp.outputImage
                }
            }
            
        case "B&W Vogue":
            if let mono = CIFilter(name: "CIPhotoEffectMono") {
                mono.setValue(inputCIImage, forKey: kCIInputImageKey)
                
                if let colorControls = CIFilter(name: "CIColorControls") {
                    colorControls.setValue(mono.outputImage ?? inputCIImage, forKey: kCIInputImageKey)
                    colorControls.setValue(1.28, forKey: kCIInputContrastKey)
                    
                    if let sharpen = CIFilter(name: "CISharpenLuminance") {
                        sharpen.setValue(colorControls.outputImage ?? inputCIImage, forKey: kCIInputImageKey)
                        sharpen.setValue(0.8, forKey: "inputSharpness")
                        outputCIImage = sharpen.outputImage
                    } else {
                        outputCIImage = colorControls.outputImage
                    }
                } else {
                    outputCIImage = mono.outputImage
                }
            }
            
        default:
            outputCIImage = inputCIImage
        }
        
        guard let finalCIImage = outputCIImage,
              let outputCGImage = ciContext.createCGImage(finalCIImage, from: inputCIImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
