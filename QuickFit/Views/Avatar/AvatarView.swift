//
//  AvatarView.swift
//  QuickFit
//

import SwiftData
import SwiftUI

struct AvatarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Avatar.createdAt, order: .reverse) private var avatars: [Avatar]
    @State private var viewModel = AvatarViewModel()
    @State private var showCamera = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
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
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Avatars")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView()
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
                
                Text(avatar.styleName)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.white)
                    .padding(8)
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

#Preview {
    AvatarView()
}
