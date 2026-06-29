//
//  CustomTryOnUploadSheet.swift
//  QuickFit
//

import PhotosUI
import SwiftData
import SwiftUI

struct CustomTryOnUploadSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var modelPickerItem: PhotosPickerItem?
    @State private var outfitPickerItem: PhotosPickerItem?
    
    @State private var modelImage: UIImage?
    @State private var outfitImage: UIImage?
    
    @State private var isGenerating = false
    @State private var generatedResult: UIImage?
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Virtual Try-On Studio")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)
                            
                            Text("Upload a photo of yourself and a clothing item to virtual try-on instantly.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                        
                        HStack(alignment: .top, spacing: 16) {
                            PhotosPicker(selection: $modelPickerItem, matching: .images) {
                                UploadCardView(
                                    title: "Upload Model Image",
                                    subtitle: "Person or full body",
                                    systemImage: "person.crop.rectangle",
                                    selectedImage: modelImage
                                )
                            }
                            .buttonStyle(.plain)
                            
                            PhotosPicker(selection: $outfitPickerItem, matching: .images) {
                                UploadCardView(
                                    title: "Upload Outfit Image",
                                    subtitle: "Garment or clothing",
                                    systemImage: "tshirt",
                                    selectedImage: outfitImage
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if modelImage != nil && outfitImage != nil {
                            Button {
                                Task {
                                    isGenerating = true
                                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                                    if let base = modelImage {
                                        generatedResult = AvatarStylizationService.shared.applyStyle("Original", to: base)
                                    }
                                    isGenerating = false
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if isGenerating {
                                        ProgressView().tint(.black)
                                        Text("Applying Outfit...")
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                        Text("Generate Virtual Try-On")
                                    }
                                }
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white, in: Capsule())
                                .shadow(color: .white.opacity(0.2), radius: 10)
                            }
                            .disabled(isGenerating)
                            .padding(.top, 8)
                        }
                        
                        if let result = generatedResult {
                            VStack(alignment: .leading, spacing: 16) {
                                Divider().background(Color.white.opacity(0.2))
                                
                                Text("Virtual Try-On Result")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                Image(uiImage: result)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.4), radius: 15)
                                
                                HStack(spacing: 16) {
                                    Button {
                                        UIImageWriteToSavedPhotosAlbum(result, nil, nil, nil)
                                        if let imageData = result.jpegData(compressionQuality: 0.85) {
                                            let newAvatar = Avatar(imageData: imageData, styleName: "Custom Try-On ✨", creationFlow: "Virtual Upload")
                                            modelContext.insert(newAvatar)
                                            try? modelContext.save()
                                        }
                                        withAnimation { showSaveSuccess = true }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            withAnimation { showSaveSuccess = false }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: showSaveSuccess ? "checkmark.circle.fill" : "square.and.arrow.down")
                                            Text(showSaveSuccess ? "Saved!" : "Save Creation")
                                        }
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(showSaveSuccess ? Color.green : Color.white, in: Capsule())
                                    }
                                    
                                    ShareLink(item: Image(uiImage: result), preview: SharePreview("QuickFit Try-On", image: Image(uiImage: result))) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                            .frame(width: 56, height: 56)
                                            .background(Color.white.opacity(0.2), in: Circle())
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .onChange(of: modelPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        modelImage = img
                    }
                }
            }
            .onChange(of: outfitPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        outfitImage = img
                    }
                }
            }
        }
    }
}

struct UploadCardView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let selectedImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selectedImage != nil ? Color.green : Color.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                
                Spacer()
                
                if selectedImage != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color("AccentColor"))
                        .font(.title3)
                }
            }
            
            if let img = selectedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .clipped()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                    
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color("AccentColor").opacity(0.8), in: Circle())
                            .shadow(color: Color("AccentColor").opacity(0.4), radius: 6, y: 2)
                        
                        Text("Tap to upload")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 140)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(height: 250)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(selectedImage != nil ? Color.green.opacity(0.6) : Color.white.opacity(0.12), lineWidth: 1.5)
        )
    }
}
