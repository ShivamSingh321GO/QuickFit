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
            if let pose = viewModel.activeOverlayPose {
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
            
            if viewModel.flashScreen {
                Color.white.ignoresSafeArea()
                    .transition(.opacity)
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
                        viewModel.triggerCapture(assetName: tryOnAssetName)
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
        .sheet(isPresented: $viewModel.showSnapshotPreview) {
            if let image = viewModel.capturedSnapshot {
                SnapshotPreviewSheet(image: image, isPresented: $viewModel.showSnapshotPreview)
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
            .tint(AppTheme.accent)
        }
    }
}

struct SnapshotPreviewSheet: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .white.opacity(0.15), radius: 15)
                        .padding()
                    
                    HStack(spacing: 16) {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            withAnimation {
                                showSaveSuccess = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation { showSaveSuccess = false }
                            }
                        } label: {
                            HStack {
                                Image(systemName: showSaveSuccess ? "checkmark.circle.fill" : "square.and.arrow.down")
                                Text(showSaveSuccess ? "Saved!" : "Save to Photos")
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(showSaveSuccess ? Color.green : Color.white, in: Capsule())
                        }
                        
                        ShareLink(item: Image(uiImage: image), preview: SharePreview("QuickFit Virtual Try-On", image: Image(uiImage: image))) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.white.opacity(0.2), in: Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Virtual Try-On Click")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .presentationDetents([.large])
    }
}
