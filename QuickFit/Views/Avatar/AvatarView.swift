//
//  AvatarView.swift
//  QuickFit
//

import SwiftData
import SwiftUI

struct AvatarView: View {
    @Query(sort: \Avatar.createdAt, order: .reverse) private var avatars: [Avatar]
    @State private var viewModel = AvatarViewModel()
    
    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 16)
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
                            description: Text("Choose Flow 1 (Photo) or Flow 2 (Skeleton) to create your stylized avatar.")
                        )
                        .foregroundStyle(.white)
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(avatars) { avatar in
                                avatarCard(for: avatar)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Avatars")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Flow 1: Photo Based", systemImage: "camera") {
                            viewModel.startCreation(flow: "Photo")
                        }
                        Button("Flow 2: Skeleton Based", systemImage: "figure.walk") {
                            viewModel.startCreation(flow: "Skeleton")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
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
    
    @ViewBuilder
    private func avatarCard(for avatar: Avatar) -> some View {
        VStack(alignment: .leading) {
            if let uiImage = UIImage(data: avatar.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 160)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
            }
            
            Text(avatar.styleName)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.top, 4)
        }
    }
}

#Preview {
    AvatarView()
}
