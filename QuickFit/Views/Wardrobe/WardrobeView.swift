//
//  WardrobeView.swift
//  QuickFit
//

import SwiftData
import SwiftUI

struct WardrobeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Garment.createdAt, order: .reverse) private var savedGarments: [Garment]
    @State private var viewModel = WardrobeViewModel()
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Rich Dark Theme Gradient Background
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        // Display user's saved items or mockup sample items
                        if savedGarments.isEmpty {
                            ForEach(Array(viewModel.filteredCards.enumerated()), id: \.element.id) { index, card in
                                NavigationLink {
                                    GarmentDetailView(
                                        name: card.name,
                                        category: card.category,
                                        rating: card.rating,
                                        description: card.description,
                                        weather: card.weather,
                                        temp: card.temp,
                                        event: card.event,
                                        assetName: card.assetName,
                                        gradientIndex: index
                                    )
                                } label: {
                                    mockupProductCard(for: card, index: index)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            ForEach(Array(savedGarments.enumerated()), id: \.element.id) { index, garment in
                                NavigationLink {
                                    GarmentDetailView(
                                        name: garment.name,
                                        category: garment.category,
                                        rating: "4.9",
                                        description: "Personal garment digitized via Vision AI background segmentation. Secured locally in your QuickFit catalog.",
                                        weather: "Custom Fit",
                                        temp: "All-Season",
                                        event: "Daily Wear",
                                        assetName: garment.assetName ?? "Versity-Jacket",
                                        gradientIndex: index
                                    )
                                } label: {
                                    savedGarmentCard(for: garment, index: index)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Wardrobe")
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $viewModel.searchText, prompt: "STYLISH T-SHIRT")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isShowingAddGarment = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddGarment) {
                scannerSheet
            }
        }
    }
    
    // MARK: - Premium Color Palette
    
    private func premiumCardGradient(index: Int) -> LinearGradient {
        let palettes = [
            [Color(hex: "2C3E50"), Color(hex: "1A252F")], // Elegant Deep Slate
            [Color(hex: "4A233E"), Color(hex: "2E1426")], // Velvet Rose Plum
            [Color(hex: "1F3A3D"), Color(hex: "122224")], // Deep Teal Dusk
            [Color(hex: "34234A"), Color(hex: "1E142B")], // Royal Amethyst
            [Color(hex: "4A3623"), Color(hex: "2B1F14")], // Warm Bronze Coffee
            [Color(hex: "4A2328"), Color(hex: "2B1417")]  // Rich Burgundy
        ]
        let chosen = palettes[abs(index) % palettes.count]
        return LinearGradient(colors: chosen, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    // MARK: - Product Card Components
    
    @ViewBuilder
    private func mockupProductCard(for card: ProductCardItem, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(premiumCardGradient(index: index))
                    .aspectRatio(0.85, contentMode: .fit)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.18), lineWidth: 1))
                
                Image(card.assetName)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
            .overlay(alignment: .topLeading) {
                Text(card.category.uppercased())
                    .font(.system(size: 8.5, weight: .heavy, design: .default))
                    .foregroundStyle(Color("AccentColor"))
                    .tracking(0.6)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.55), in: Capsule())
                    .padding(12)
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    viewModel.toggleFavorite(for: card.id)
                } label: {
                    Image(systemName: card.isFavorite ? "heart.fill" : "heart")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(card.isFavorite ? .red : .white)
                        .frame(width: 34, height: 34)
                        .background(Color.black.opacity(0.6), in: Circle())
                }
                .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(card.name.uppercased())
                    .font(.system(.subheadline, design: .default).weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
    }
    
    @ViewBuilder
    private func savedGarmentCard(for garment: Garment, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(premiumCardGradient(index: index))
                    .aspectRatio(0.85, contentMode: .fit)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.18), lineWidth: 1))
                
                Image(garment.assetName ?? "Versity-Jacket")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
            .overlay(alignment: .topLeading) {
                Text(garment.category.uppercased())
                    .font(.system(size: 8.5, weight: .heavy, design: .default))
                    .foregroundStyle(Color("AccentColor"))
                    .tracking(0.6)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.55), in: Capsule())
                    .padding(12)
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    // toggle favorite
                } label: {
                    Image(systemName: "heart")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.black.opacity(0.6), in: Circle())
                }
                .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(garment.name.uppercased())
                    .font(.system(.subheadline, design: .default).weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Sheets
    
    private var scannerSheet: some View {
        NavigationStack {
            ContentUnavailableView(
                "Garment Scanner",
                systemImage: "camera.viewfinder",
                description: Text("VNGenerateForegroundInstanceMask segmentation flow will be integrated here.")
            )
            .navigationTitle("Add Garment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { viewModel.isShowingAddGarment = false }
                }
            }
        }
    }
}

#Preview {
    WardrobeView()
}
