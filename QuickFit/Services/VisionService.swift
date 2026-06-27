//
//  VisionService.swift
//  QuickFit
//

import CoreMedia
import Foundation
import Vision

struct DetectedJoint {
    let point: CGPoint // Vision normalized (0...1), bottom-left origin
    let confidence: Float
    
    func screenPoint(in size: CGSize, isMirrored: Bool = true, videoAspect: CGFloat = 9.0 / 16.0) -> CGPoint {
        var normX = point.x
        if isMirrored {
            normX = 1.0 - normX
        }
        let normY = 1.0 - point.y
        
        let viewAspect = size.width / size.height
        if viewAspect < videoAspect {
            let scaledWidth = size.height * videoAspect
            let overflowX = scaledWidth - size.width
            let sx = (normX * scaledWidth) - (overflowX / 2.0)
            let sy = normY * size.height
            return CGPoint(x: sx, y: sy)
        } else {
            let scaledHeight = size.width / videoAspect
            let overflowY = scaledHeight - size.height
            let sx = normX * size.width
            let sy = (normY * scaledHeight) - (overflowY / 2.0)
            return CGPoint(x: sx, y: sy)
        }
    }
}

struct DetectedBodyPose {
    let neck: DetectedJoint?
    let leftShoulder: DetectedJoint?
    let rightShoulder: DetectedJoint?
    let leftHip: DetectedJoint?
    let rightHip: DetectedJoint?
    let leftAnkle: DetectedJoint?
    let rightAnkle: DetectedJoint?
    let leftEar: DetectedJoint?
    let rightEar: DetectedJoint?
    
    var isFullyTracked: Bool {
        guard let leftAnkle, let rightAnkle, let neck else { return false }
        return leftAnkle.confidence > 0.3 && rightAnkle.confidence > 0.3 && neck.confidence > 0.3
    }
}

final class VisionService {
    private let requestHandler = VNSequenceRequestHandler()
    private var isProcessing = false
    
    var onPoseDetected: ((DetectedBodyPose?) -> Void)?
    var onStatusMessage: ((String) -> Void)?

    init() {}
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard !isProcessing else { return }
        isProcessing = true
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessing = false
            return
        }
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] req, error in
            defer { self?.isProcessing = false }
            guard let self, error == nil,
                  let results = req.results as? [VNHumanBodyPoseObservation],
                  let observation = results.first else {
                self?.onPoseDetected?(nil)
                self?.onStatusMessage?("Step into frame")
                return
            }
            
            let pose = self.extractPose(from: observation)
            self.onPoseDetected?(pose)
            self.evaluateFraming(pose)
        }
        
        do {
            try requestHandler.perform([request], on: pixelBuffer, orientation: .up)
        } catch {
            isProcessing = false
        }
    }
    
    private func extractPose(from obs: VNHumanBodyPoseObservation) -> DetectedBodyPose {
        func joint(_ name: VNHumanBodyPoseObservation.JointName) -> DetectedJoint? {
            guard let pt = try? obs.recognizedPoint(name), pt.confidence > 0.1 else { return nil }
            return DetectedJoint(point: pt.location, confidence: pt.confidence)
        }
        
        return DetectedBodyPose(
            neck: joint(.neck),
            leftShoulder: joint(.leftShoulder),
            rightShoulder: joint(.rightShoulder),
            leftHip: joint(.leftHip),
            rightHip: joint(.rightHip),
            leftAnkle: joint(.leftAnkle),
            rightAnkle: joint(.rightAnkle),
            leftEar: joint(.leftEar),
            rightEar: joint(.rightEar)
        )
    }
    
    private func evaluateFraming(_ pose: DetectedBodyPose) {
        let hasAnkles = (pose.leftAnkle?.confidence ?? 0) > 0.3 || (pose.rightAnkle?.confidence ?? 0) > 0.3
        let hasHead = (pose.neck?.confidence ?? 0) > 0.3 || (pose.leftEar?.confidence ?? 0) > 0.3
        
        if !hasAnkles {
            onStatusMessage?("Stand back until full body is visible")
        } else if !hasHead {
            onStatusMessage?("Adjust phone tilt to include head")
        } else {
            onStatusMessage?("Full body tracked - Hold still")
        }
    }
    
    func calculateProportions(from pose: DetectedBodyPose) -> (shoulderWidth: Double, hipWidth: Double, torsoHeight: Double)? {
        guard let lShoulder = pose.leftShoulder?.point, let rShoulder = pose.rightShoulder?.point,
              let lHip = pose.leftHip?.point, let rHip = pose.rightHip?.point else {
            return nil
        }
        
        let shoulderDist = hypot(lShoulder.x - rShoulder.x, lShoulder.y - rShoulder.y)
        let hipDist = hypot(lHip.x - rHip.x, lHip.y - rHip.y)
        
        let midShoulder = CGPoint(x: (lShoulder.x + rShoulder.x) / 2, y: (lShoulder.y + rShoulder.y) / 2)
        let midHip = CGPoint(x: (lHip.x + rHip.x) / 2, y: (lHip.y + rHip.y) / 2)
        let torsoDist = hypot(midShoulder.x - midHip.x, midShoulder.y - midHip.y)
        
        return (Double(shoulderDist), Double(hipDist), Double(torsoDist))
    }
}
