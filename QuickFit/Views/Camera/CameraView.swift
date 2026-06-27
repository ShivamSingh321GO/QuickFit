//
//  CameraView.swift
//  QuickFit
//

import AVFoundation
import SwiftUI

struct CameraView: View {
    var tryOnAssetName: String = "Blue-shirt"
    @State private var viewModel = CameraViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                switch viewModel.authorizationStatus {
                case .authorized:
                    liveCameraLayout
                case .denied, .restricted:
                    permissionDeniedLayout
                case .notDetermined:
                    ProgressView()
                        .tint(.white)
                @unknown default:
                    EmptyView()
                }
            }
            .navigationTitle("Virtual Try-On")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.checkPermissionAndStart()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
        }
    }
    
    private var liveCameraLayout: some View {
        ZStack {
            CameraPreviewRepresentable(session: viewModel.cameraService.captureSession)
                .ignoresSafeArea()
            
            // Real-Time 2D Cloth Try-On Tracking Overlay
            if let pose = viewModel.currentPose {
                VirtualClothOverlayView(
                    pose: pose,
                    assetName: tryOnAssetName,
                    isFrontCamera: viewModel.isFrontCamera
                )
                .ignoresSafeArea()
                .animation(.interactiveSpring(response: 0.12, dampingFraction: 0.85), value: pose.neck?.point)
            }
            
            if viewModel.showSkeleton {
                SkeletonView(
                    pose: viewModel.currentPose,
                    isFrontCamera: viewModel.isFrontCamera
                )
                .ignoresSafeArea()
                    .transition(.opacity.animation(.easeInOut))
            }
            
            // Top guidance badge
            VStack {
                HStack {
                    Image(systemName: "person.fill.viewfinder")
                    Text(viewModel.trackingStatusMessage)
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 8)
                
                Spacer()
                
                // Bottom floating toolbar
                HStack(spacing: 24) {
                    Button {
                        viewModel.toggleSkeleton()
                    } label: {
                        Image(systemName: viewModel.showSkeleton ? "figure.walk" : "figure.walk.motion")
                            .font(.title3)
                            .foregroundStyle(viewModel.showSkeleton ? .yellow : .white)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Button {
                        // Capture snapshot flow (Feature 2 hook)
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .frame(width: 72, height: 72)
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                        }
                    }
                    
                    Button {
                        viewModel.switchCamera()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }
    
    private var permissionDeniedLayout: some View {
        ContentUnavailableView {
            Label("Camera Access Required", systemImage: "video.slash.fill")
        } description: {
            Text("AvatarX needs camera permission to capture body pose tracking and display live virtual try-on overlays.")
        } actions: {
            Button("Open Settings") {
                viewModel.openSettings()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
