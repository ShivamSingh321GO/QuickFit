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
    var lastValidPose: DetectedBodyPose?
    var activeGarment: Garment?
    
    var capturedSnapshot: UIImage?
    var showSnapshotPreview: Bool = false
    var flashScreen: Bool = false
    var currentCaptureAssetName: String?
    
    var activeOverlayPose: DetectedBodyPose? {
        if let current = currentPose,
           let nk = current.neck, nk.confidence > 0.01,
           ((current.leftShoulder?.confidence ?? 0) > 0.01 || (current.rightShoulder?.confidence ?? 0) > 0.01) {
            return current
        }
        return lastValidPose
    }
    
    let cameraService = CameraService()
    let visionService = VisionService()
    
    init() {
        cameraService.onFrameCaptured = { [weak self] sampleBuffer in
            guard let self else { return }
            self.visionService.processFrame(sampleBuffer)
        }
        
        cameraService.onSnapshotCaptured = { [weak self] cameraImage in
            guard let self else { return }
            self.processSnapshotComposite(cameraImage: cameraImage)
        }
        
        visionService.onPoseDetected = { [weak self] pose in
            DispatchQueue.main.async {
                guard let self else { return }
                self.currentPose = pose
                if let p = pose,
                   let nk = p.neck, nk.confidence > 0.02,
                   ((p.leftShoulder?.confidence ?? 0) > 0.02 || (p.rightShoulder?.confidence ?? 0) > 0.02) {
                    self.lastValidPose = p
                }
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
        currentPose = nil
        lastValidPose = nil
        cameraService.switchCamera(to: isFrontCamera ? .front : .back)
    }
    
    func triggerCapture(assetName: String) {
        self.currentCaptureAssetName = assetName
        withAnimation(.easeOut(duration: 0.1)) {
            flashScreen = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.15)) {
                self.flashScreen = false
            }
        }
        cameraService.takeSnapshot(isFrontCamera: isFrontCamera)
    }
    
    @MainActor
    private func processSnapshotComposite(cameraImage: UIImage) {
        guard let pose = activeOverlayPose, let assetName = currentCaptureAssetName, assetName != "None" else {
            self.capturedSnapshot = cameraImage
            self.showSnapshotPreview = true
            return
        }
        
        let compositeView = CompositeSnapshotView(
            cameraImage: cameraImage,
            pose: pose,
            assetName: assetName,
            isFrontCamera: isFrontCamera
        )
        
        let renderer = ImageRenderer(content: compositeView)
        renderer.scale = 1.0
        if let compositedImage = renderer.uiImage {
            self.capturedSnapshot = compositedImage
        } else {
            self.capturedSnapshot = cameraImage
        }
        self.showSnapshotPreview = true
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
