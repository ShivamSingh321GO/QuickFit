//
//  FavoritesView.swift
//  QuickFit
//

import SwiftUI

struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: WardrobeViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                let favoriteCards = viewModel.dummyCards.filter { $0.isFavorite }
                
                if favoriteCards.isEmpty {
                    ContentUnavailableView(
                        "No Favorites Yet",
                        systemImage: "heart.slash",
                        description: Text("Tap the heart icon on any garment in your wardrobe to add it to your favorites.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(Array(favoriteCards.enumerated()), id: \.element.id) { index, card in
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
                                    favoriteProductCard(for: card, index: index)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Favorites ❤️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(Color("AccentColor"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func premiumCardGradient(index: Int) -> LinearGradient {
        let palettes = [
            [Color(hex: "2C3E50"), Color(hex: "1A252F")],
            [Color(hex: "4A233E"), Color(hex: "2E1426")],
            [Color(hex: "1F3A3D"), Color(hex: "122224")],
            [Color(hex: "34234A"), Color(hex: "1E142B")],
            [Color(hex: "4A3623"), Color(hex: "2B1F14")],
            [Color(hex: "4A2328"), Color(hex: "2B1417")]
        ]
        let chosen = palettes[abs(index) % palettes.count]
        return LinearGradient(colors: chosen, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    @ViewBuilder
    private func favoriteProductCard(for card: ProductCardItem, index: Int) -> some View {
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
}
