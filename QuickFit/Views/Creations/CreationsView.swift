//
//  CreationsView.swift
//  QuickFit
//

import SwiftData
import SwiftUI

struct CreationsView: View {
    @State private var showCamera = false
    @State private var selectedCreation: Avatar?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                CreationsGridView(selectedCreation: $selectedCreation)
            }
            .navigationTitle("Creations")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCamera = true
                    } label: {
                        Image(systemName: "wand.and.sparkles")
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CustomTryOnUploadSheet()
            }
            .sheet(item: $selectedCreation) { creation in
                CreationDetailSheet(creation: creation)
            }
        }
    }
}

struct CreationsGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Avatar> { $0.creationFlow == "Virtual Upload" }, sort: \Avatar.createdAt, order: .reverse) private var creations: [Avatar]
    
    @Binding var selectedCreation: Avatar?
    @State private var selectedCategory: String = "All"
    
    private let categories = ["All", "Original", "Vintage Film", "Cyber Neon", "Anime Pastel", "Golden Hour", "B&W Vogue"]
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    private var filteredCreations: [Avatar] {
        if selectedCategory == "All" {
            return creations
        }
        return creations.filter { $0.styleName.contains(selectedCategory) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !creations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedCategory = category
                                }
                            } label: {
                                Text(category)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == category ? Color.white : Color.white.opacity(0.15))
                                    )
                                    .foregroundStyle(selectedCategory == category ? .black : .white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            
            ScrollView {
                if creations.isEmpty {
                    ContentUnavailableView(
                        "No Creations Yet",
                        systemImage: "sparkles.rectangle.stack",
                        description: Text("Your virtual try-on photos and stylized avatars saved from the camera studio will appear here.")
                    )
                    .foregroundStyle(.white)
                    .padding(.top, 80)
                } else if filteredCreations.isEmpty {
                    ContentUnavailableView(
                        "No \(selectedCategory) Creations",
                        systemImage: "photo.stack",
                        description: Text("You haven't saved any try-on creations with this style yet.")
                    )
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredCreations) { creation in
                            creationCard(for: creation)
                                .onTapGesture {
                                    selectedCreation = creation
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
    
    @ViewBuilder
    private func creationCard(for creation: Avatar) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                if let uiImage = UIImage(data: creation.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 200)
                        .overlay {
                            Image(systemName: "photo.fill")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                }
                
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(creation.styleName.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))
                        .tracking(0.8)
                    
                    Text(creation.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(12)
            }
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .contentShape(Rectangle())
        .contextMenu {
            ShareLink(item: Image(uiImage: UIImage(data: creation.imageData) ?? UIImage()), preview: SharePreview("QuickFit Creation", image: Image(uiImage: UIImage(data: creation.imageData) ?? UIImage()))) {
                Label("Share Creation", systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive) {
                withAnimation {
                    modelContext.delete(creation)
                }
            } label: {
                Label("Delete Creation", systemImage: "trash")
            }
        }
    }
}

struct CreationDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let creation: Avatar
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let uiImage = UIImage(data: creation.imageData) {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .white.opacity(0.15), radius: 20)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 6) {
                            Text(creation.styleName)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            
                            Text("Created on \(creation.createdAt.formatted(date: .long, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button {
                                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                withAnimation { showSaveSuccess = true }
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
                            
                            ShareLink(item: Image(uiImage: uiImage), preview: SharePreview("QuickFit Creation", image: Image(uiImage: uiImage))) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.white.opacity(0.2), in: Circle())
                            }
                            
                            Button(role: .destructive) {
                                modelContext.delete(creation)
                                dismiss()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                                    .frame(width: 56, height: 56)
                                    .background(Color.red.opacity(0.15), in: Circle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                } else {
                    ContentUnavailableView("Image Unavailable", systemImage: "photo.slash")
                }
            }
            .navigationTitle("Creation Detail")
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
