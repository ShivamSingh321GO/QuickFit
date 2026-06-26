//
//  WardrobeViewModel.swift
//  QuickFit
//

import Observation
import SwiftData
import SwiftUI

struct ProductCardItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let rating: String
    let description: String
    let weather: String
    let temp: String
    let event: String
    let assetName: String
    var isFavorite: Bool = false
}

@Observable
final class WardrobeViewModel {
    var searchText: String = ""
    var selectedCategory: String = "All"
    var isShowingAddGarment: Bool = false
    
    // Curated premium outfit cards with distinct editorial descriptions and event metadata
    var dummyCards: [ProductCardItem] = [
        ProductCardItem(
            name: "Wet Weather Elegance",
            category: "Cozy Wear",
            rating: "4.8",
            description: "Experience premium comfort and effortless protection against the elements. Crafted from water-resistant technical satin with thermal insulation, perfect for brisk autumn strolls.",
            weather: "Rainy / Autumn",
            temp: "16-22°C",
            event: "Promenade",
            assetName: "Versity-Jacket",
            isFavorite: true
        ),
        ProductCardItem(
            name: "Varsity Noir Luxe",
            category: "Streetwear",
            rating: "4.9",
            description: "Classic collegiate aesthetics remastered with ultra-soft wool fleece and contrasting vegan leather trims. A definitive statement piece for urban city nights.",
            weather: "Chilly / Evening",
            temp: "10-18°C",
            event: "City Outing",
            assetName: "Versity-Jacket",
            isFavorite: false
        ),
        ProductCardItem(
            name: "Retro Campus Bomber",
            category: "Vintage Casual",
            rating: "4.7",
            description: "Inspired by 1990s varsity athletes, featuring heavyweight cotton twill and custom ribbed collar detailing. Effortlessly pairs with relaxed denim and classic sneakers.",
            weather: "Breezy / Spring",
            temp: "18-24°C",
            event: "Campus Day",
            assetName: "Versity-Jacket",
            isFavorite: true
        ),
        ProductCardItem(
            name: "Royal Amethyst Crest",
            category: "High Fashion",
            rating: "5.0",
            description: "A striking fusion of regal jewel tones and modern streetwear silhouette. Tailored for those who demand attention at exclusive social gatherings and gallery openings.",
            weather: "Cool / Indoor",
            temp: "19-25°C",
            event: "Art Gallery",
            assetName: "Versity-Jacket",
            isFavorite: false
        ),
        ProductCardItem(
            name: "Autumn Bronze Tailored",
            category: "Smart Casual",
            rating: "4.6",
            description: "Warm earthy hues meet structured tailoring. Designed for seamless aesthetic transitions from afternoon cafe meetings to relaxed evening dinners.",
            weather: "Mild / Sunset",
            temp: "15-21°C",
            event: "Cafe Meet",
            assetName: "Versity-Jacket",
            isFavorite: false
        ),
        ProductCardItem(
            name: "Crimson Sport Edition",
            category: "Athleisure",
            rating: "4.8",
            description: "High-visibility crimson colorway built for active lifestyles. Features breathable mesh lining and ergonomic shoulder seams for uncompromised daily mobility.",
            weather: "Sunny / Windy",
            temp: "14-20°C",
            event: "Weekend Sport",
            assetName: "Versity-Jacket",
            isFavorite: true
        )
    ]
    
    var filteredCards: [ProductCardItem] {
        if searchText.isEmpty {
            return dummyCards
        }
        return dummyCards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func toggleFavorite(for id: UUID) {
        if let index = dummyCards.firstIndex(where: { $0.id == id }) {
            dummyCards[index].isFavorite.toggle()
        }
    }
}
