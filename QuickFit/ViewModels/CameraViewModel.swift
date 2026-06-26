//
//  CameraViewModel.swift
//  QuickFit
//

import AVFoundation
import Observation
import SwiftData
import SwiftUI
import UIKit

@Observable
final class CameraViewModel {
    var authorizationStatus: AVAuthorizationStatus = .notDetermined
    var isFrontCamera: Bool = true
    var showSkeleton: Bool = false
    var trackingStatusMessage: String = "Stand back until full body is visible"
    var currentPose: DetectedBodyPose?
    var activeGarment: Garment?
    
    let cameraService = CameraService()
    let visionService = VisionService()
    
    init() {
        cameraService.onFrameCaptured = { [weak self] sampleBuffer in
            guard let self else { return }
            self.visionService.processFrame(sampleBuffer)
        }
        
        visionService.onPoseDetected = { [weak self] pose in
            DispatchQueue.main.async {
                self?.currentPose = pose
            }
        }
        
        visionService.onStatusMessage = { [weak self] message in
            DispatchQueue.main.async {
                self?.trackingStatusMessage = message
            }
        }
    }
    
    func checkPermissionAndStart() {
        cameraService.checkPermissions { [weak self] status in
            guard let self else { return }
            self.authorizationStatus = status
            if status == .authorized {
                self.cameraService.configureSession(position: self.isFrontCamera ? .front : .back)
                self.cameraService.startSession()
            }
        }
    }
    
    func onDisappear() {
        cameraService.stopSession()
    }
    
    func toggleSkeleton() {
        showSkeleton.toggle()
    }
    
    func switchCamera() {
        isFrontCamera.toggle()
        cameraService.switchCamera(to: isFrontCamera ? .front : .back)
    }
    
    func saveBiometricSnapshot(context: ModelContext) -> BodyMeasurement? {
        guard let pose = currentPose,
              let props = visionService.calculateProportions(from: pose) else {
            return nil
        }
        
        let estHeight = props.torsoHeight * 3.2 // Anthropometric estimation approximation
        let measurement = BodyMeasurement(
            shoulderWidth: props.shoulderWidth,
            hipWidth: props.hipWidth,
            torsoHeight: props.torsoHeight,
            estimatedHeight: estHeight
        )
        context.insert(measurement)
        try? context.save()
        return measurement
    }
    
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
