//
//  CameraView.swift
//  QuickFit
//

import AVFoundation
import SwiftData
import SwiftUI

struct CameraView: View {
    @State private var selectedGarment: String
    @State private var viewModel = CameraViewModel()
    private let showGarmentPicker: Bool
    
    private let availableGarments = ["None", "Blue-shirt", "Green-Shirt", "Red-shirtCheck", "T-Shirt", "Green-FullSleeve"]
    
    init(tryOnAssetName: String? = nil) {
        if let assetName = tryOnAssetName {
            _selectedGarment = State(initialValue: assetName)
            self.showGarmentPicker = false
        } else {
            _selectedGarment = State(initialValue: "Blue-shirt")
            self.showGarmentPicker = true
        }
    }

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
                viewModel.currentCaptureAssetName = selectedGarment
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
            if selectedGarment != "None", let pose = viewModel.activeOverlayPose {
                VirtualClothOverlayView(
                    pose: pose,
                    assetName: selectedGarment,
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
                
                // Instagram-style Garment Picker Carousel
                if showGarmentPicker {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(availableGarments, id: \.self) { garment in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedGarment = garment
                                        viewModel.currentCaptureAssetName = garment
                                    }
                                } label: {
                                    ZStack {
                                        if selectedGarment == garment {
                                            Circle()
                                                .stroke(.white, lineWidth: 3.5)
                                                .frame(width: 68, height: 68)
                                        }
                                        
                                        if garment == "None" {
                                            Image(systemName: "circle.slash")
                                                .font(.system(size: selectedGarment == garment ? 26 : 22, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .frame(width: selectedGarment == garment ? 42 : 34, height: selectedGarment == garment ? 42 : 34)
                                                .padding(8)
                                                .background(
                                                    Circle()
                                                        .fill(selectedGarment == garment ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                                                )
                                                .frame(width: 56, height: 56)
                                        } else {
                                            Image(garment)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: selectedGarment == garment ? 42 : 34, height: selectedGarment == garment ? 42 : 34)
                                                .padding(8)
                                                .background(
                                                    Circle()
                                                        .fill(selectedGarment == garment ? Color.white.opacity(0.95) : Color.white.opacity(0.35))
                                                )
                                                .frame(width: 56, height: 56)
                                        }
                                    }
                                    .scaleEffect(selectedGarment == garment ? 1.05 : 0.9)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                    }
                    .padding(.bottom, 12)
                }
                
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
                        viewModel.currentCaptureAssetName = selectedGarment
                        viewModel.triggerCapture(assetName: selectedGarment)
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
    @Environment(\.modelContext) private var modelContext
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var showSaveSuccess = false
    
    @State private var displayImage: UIImage
    @State private var cutoutImage: UIImage?
    @State private var isProcessing = false
    @State private var selectedStyle: String = "Original"
    @State private var removeBackground: Bool = false
    
    private let styles = ["Original", "Vintage Film", "Cyber Neon", "Anime Pastel", "Golden Hour", "B&W Vogue"]
    
    init(image: UIImage, isPresented: Binding<Bool>) {
        self.image = image
        self._isPresented = isPresented
        self._displayImage = State(initialValue: image)
    }
    
    private func updateDisplayImage(style: String, removeBg: Bool) {
        if removeBg {
            if let base = cutoutImage {
                displayImage = AvatarStylizationService.shared.applyStyle(style, to: base)
            } else {
                Task {
                    isProcessing = true
                    let removed = await AvatarStylizationService.shared.removeBackground(from: image)
                    cutoutImage = removed
                    isProcessing = false
                    displayImage = AvatarStylizationService.shared.applyStyle(style, to: removed)
                }
            }
        } else {
            displayImage = AvatarStylizationService.shared.applyStyle(style, to: image)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ZStack {
                        Image(uiImage: displayImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .white.opacity(0.15), radius: 15)
                            .padding(.horizontal)
                        
                        if isProcessing {
                            ZStack {
                                Color.black.opacity(0.6)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.2)
                                    Text("Removing Background...")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Background Removal Toggle Button
                    HStack {
                        Button {
                            let newValue = !removeBackground
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                removeBackground = newValue
                            }
                            updateDisplayImage(style: selectedStyle, removeBg: newValue)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: removeBackground ? "wand.and.stars.inverse" : "wand.and.stars")
                                Text(removeBackground ? "Background Removed ✨" : "Remove Background")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(removeBackground ? Color.white : Color.white.opacity(0.15))
                            )
                            .foregroundStyle(removeBackground ? .black : .white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // CoreImage Avatar Style Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AVATAR STYLE (COREIMAGE)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(styles, id: \.self) { style in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                            selectedStyle = style
                                        }
                                        updateDisplayImage(style: style, removeBg: removeBackground)
                                    } label: {
                                        Text(style)
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(selectedStyle == style ? Color.white : Color.white.opacity(0.15))
                                            )
                                            .foregroundStyle(selectedStyle == style ? .black : .white)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer(minLength: 4)
                    
                    HStack(spacing: 16) {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(displayImage, nil, nil, nil)
                            
                            // Save created Avatar to SwiftData
                            if let imageData = displayImage.jpegData(compressionQuality: 0.85) {
                                let styleLabel = removeBackground ? "\(selectedStyle) ✨" : selectedStyle
                                let newAvatar = Avatar(imageData: imageData, styleName: styleLabel, creationFlow: "Camera Studio")
                                modelContext.insert(newAvatar)
                                try? modelContext.save()
                            }
                            
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
                        
                        ShareLink(item: Image(uiImage: displayImage), preview: SharePreview("QuickFit Avatar", image: Image(uiImage: displayImage))) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.white.opacity(0.2), in: Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
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
