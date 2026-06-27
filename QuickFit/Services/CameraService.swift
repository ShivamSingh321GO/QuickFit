//
//  CameraService.swift
//  QuickFit
//

import AVFoundation
import CoreMedia
import Foundation
import UIKit

final class CameraService: NSObject {
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.avatarX.cameraQueue")
    private let videoOutput = AVCaptureVideoDataOutput()
    
    var onFrameCaptured: ((CMSampleBuffer) -> Void)?
    var onSnapshotCaptured: ((UIImage) -> Void)?
    private var activeVideoInput: AVCaptureDeviceInput?
    private var requestSnapshot = false
    private var snapshotIsFrontCamera = true

    override init() {
        super.init()
    }
    
    func checkPermissions(completion: @escaping (AVAuthorizationStatus) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async {
                    completion(AVCaptureDevice.authorizationStatus(for: .video))
                }
            }
        default:
            completion(status)
        }
    }
    
    func configureSession(position: AVCaptureDevice.Position = .front) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high
            
            // Remove existing inputs
            if let activeInput = self.activeVideoInput {
                self.captureSession.removeInput(activeInput)
            }
            
            // Add Device Input
            guard let camera = self.cameraDevice(for: position),
                  let deviceInput = try? AVCaptureDeviceInput(device: camera) else {
                self.captureSession.commitConfiguration()
                return
            }
            
            if self.captureSession.canAddInput(deviceInput) {
                self.captureSession.addInput(deviceInput)
                self.activeVideoInput = deviceInput
            }
            
            // Add Video Output if needed
            if !self.captureSession.outputs.contains(self.videoOutput) {
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
                ]
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                
                if self.captureSession.canAddOutput(self.videoOutput) {
                    self.captureSession.addOutput(self.videoOutput)
                }
            }
            
            // Keep video output unmirrored so sensor space matches Vision normalized coordinates 1:1
            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = false
                }
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
    
    func switchCamera(to position: AVCaptureDevice.Position) {
        configureSession(position: position)
    }
    
    func takeSnapshot(isFrontCamera: Bool) {
        sessionQueue.async { [weak self] in
            self?.snapshotIsFrontCamera = isFrontCamera
            self?.requestSnapshot = true
        }
    }
    
    private func cameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return device
        }
        return AVCaptureDevice.default(for: .video)
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onFrameCaptured?(sampleBuffer)
        
        if requestSnapshot {
            requestSnapshot = false
            let isFront = snapshotIsFrontCamera
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let context = CIContext()
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    let orientation: UIImage.Orientation = isFront ? .upMirrored : .up
                    let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
                    DispatchQueue.main.async { [weak self] in
                        self?.onSnapshotCaptured?(uiImage)
                    }
                }
            }
        }
    }
}
