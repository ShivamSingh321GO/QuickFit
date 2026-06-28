//
//  AvatarView.swift
//  QuickFit
//

import SwiftData
import SwiftUI

struct AvatarView: View {
    @State private var viewModel = AvatarViewModel()
    @State private var showCamera = false
    @State private var selectedAvatar: Avatar?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                AvatarGridView(selectedAvatar: $selectedAvatar)
            }
            .navigationTitle("Avatars")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView()
            }
            .sheet(item: $selectedAvatar) { avatar in
                AvatarDetailSheet(avatar: avatar) {
                    showCamera = true
                }
            }
            .sheet(isPresented: $viewModel.isShowingCreationFlow) {
                NavigationStack {
                    ContentUnavailableView(
                        "Avatar Studio: \(viewModel.selectedCreationFlow)",
                        systemImage: "wand.and.stars",
                        description: Text("CoreImage stylization filters and foreground mask pipeline.")
                    )
                    .navigationTitle("New Avatar")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { viewModel.isShowingCreationFlow = false }
                        }
                    }
                }
            }
        }
    }
}

struct AvatarGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Avatar> { $0.creationFlow == "Camera Studio" }, sort: \Avatar.createdAt, order: .reverse) private var avatars: [Avatar]
    @Binding var selectedAvatar: Avatar?
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            if avatars.isEmpty {
                ContentUnavailableView(
                    "No Avatars Created",
                    systemImage: "person.crop.artframe",
                    description: Text("Tap the camera icon above to capture your body pose and create your stylized avatar.")
                )
                .foregroundStyle(.white)
                .padding(.top, 60)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Created Avatars")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(avatars) { avatar in
                            avatarCard(for: avatar)
                                .onTapGesture {
                                    selectedAvatar = avatar
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    @ViewBuilder
    private func avatarCard(for avatar: Avatar) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                if let uiImage = UIImage(data: avatar.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 180)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(avatar.styleName.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))
                        .tracking(0.8)
                    
                    Text(avatar.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(10)
            }
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(avatar)
            } label: {
                Label("Delete Avatar", systemImage: "trash")
            }
        }
    }
}

struct AvatarDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let avatar: Avatar
    let onRetake: () -> Void
    
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let uiImage = UIImage(data: avatar.imageData) {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .white.opacity(0.15), radius: 20)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 6) {
                            Text(avatar.styleName)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            
                            Text("Created on \(avatar.createdAt.formatted(date: .long, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            // Delete Button
                            Button(role: .destructive) {
                                modelContext.delete(avatar)
                                try? modelContext.save()
                                dismiss()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.red)
                                    .frame(width: 56, height: 56)
                                    .background(Color.red.opacity(0.15), in: Circle())
                            }
                            
                            // Retake Button
                            Button {
                                dismiss()
                                onRetake()
                            } label: {
                                HStack {
                                    Image(systemName: "camera.arrow.triangle.2.circlepath")
                                    Text("Retake")
                                }
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white, in: Capsule())
                            }
                            
                            // Save to Photos (Download) Button
                            Button {
                                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                withAnimation { showSaveSuccess = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation { showSaveSuccess = false }
                                }
                            } label: {
                                ZStack {
                                    Image(systemName: showSaveSuccess ? "checkmark" : "square.and.arrow.down")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(showSaveSuccess ? .green : .white)
                                }
                                .frame(width: 56, height: 56)
                                .background(Color.white.opacity(0.15), in: Circle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                } else {
                    ContentUnavailableView("Image Unavailable", systemImage: "photo.slash")
                }
            }
            .navigationTitle("Avatar Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    AvatarView()
}
