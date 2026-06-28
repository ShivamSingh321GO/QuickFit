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
    @State private var showFavorites = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let categories = [
        "All", "Smart Casual", "Eco Luxury", "Heritage Casual", "Modern Basic", "Active Outdoor",
        "Tops", "Bottoms", "Shoes", "Accessories"
    ]
    
    private var filteredSavedGarments: [Garment] {
        var result = savedGarments
        if viewModel.selectedCategory != "All" {
            result = result.filter { $0.category.localizedCaseInsensitiveContains(viewModel.selectedCategory) }
        }
        if !viewModel.searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(viewModel.searchText) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Rich Dark Theme Gradient Background
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category Filter Pills (Bubble style)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        viewModel.selectedCategory = category
                                    }
                                } label: {
                                    Text(category)
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(viewModel.selectedCategory == category ? Color("AccentColor") : Color.white.opacity(0.15))
                                        )
                                        .foregroundStyle(viewModel.selectedCategory == category ? .black : .white)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    ScrollView {
                        if savedGarments.isEmpty {
                            let cards = viewModel.filteredCards
                            if cards.isEmpty {
                                ContentUnavailableView(
                                    "No Matching Items",
                                    systemImage: "hanger",
                                    description: Text("No items found matching \"\(viewModel.selectedCategory)\".")
                                )
                                .foregroundStyle(.white)
                                .padding(.top, 60)
                            } else {
                                LazyVGrid(columns: columns, spacing: 24) {
                                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
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
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 32)
                            }
                        } else {
                            let garments = filteredSavedGarments
                            if garments.isEmpty {
                                ContentUnavailableView(
                                    "No Matching Items",
                                    systemImage: "hanger",
                                    description: Text("No items found matching \"\(viewModel.selectedCategory)\".")
                                )
                                .foregroundStyle(.white)
                                .padding(.top, 60)
                            } else {
                                LazyVGrid(columns: columns, spacing: 24) {
                                    ForEach(Array(garments.enumerated()), id: \.element.id) { index, garment in
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
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 32)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wardrobe")
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $viewModel.searchText, prompt: "STYLISH T-SHIRT")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFavorites = true
                    } label: {
                        Image(systemName: "heart.fill")
                    }
                }
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesView(viewModel: viewModel)
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.category.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))
                    .tracking(0.8)
                
                Text(card.name)
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 36, alignment: .topLeading)
            }
            .padding(.horizontal, 6)
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(garment.category.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))
                    .tracking(0.8)
                
                Text(garment.name)
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 36, alignment: .topLeading)
            }
            .padding(.horizontal, 6)
        }
    }
}

#Preview {
    WardrobeView()
}
