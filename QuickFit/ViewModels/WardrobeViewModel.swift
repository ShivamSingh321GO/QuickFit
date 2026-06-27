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
            name: "Azure Utilitarian Oxford",
            category: "Smart Casual",
            rating: "4.9",
            description: "Inspired by utilitarian workwear aesthetics. Features breathable azure blue weave with dual chest pockets and mother-of-pearl snap closures.",
            weather: "Breezy / Spring",
            temp: "18-25°C",
            event: "Weekend Trip",
            assetName: "Blue-shirt",
            isFavorite: true
        ),
        ProductCardItem(
            name: "Forest Green Corduroy",
            category: "Eco Luxury",
            rating: "5.0",
            description: "Crafted from sustainable organic cotton corduroy in a rich emerald forest hue. Features horn buttons and a relaxed overshirt silhouette perfect for layering.",
            weather: "Crisp / Autumn",
            temp: "14-21°C",
            event: "Nature Retreat",
            assetName: "Green-Shirt",
            isFavorite: false
        ),
        ProductCardItem(
            name: "Crimson Lumberjack Flannel",
            category: "Heritage Casual",
            rating: "4.9",
            description: "Classic heritage flannel crafted from ultra-soft brushed heavyweight cotton in a striking crimson and obsidian checkered plaid weave. Built for chilly fireside evenings.",
            weather: "Crisp / Autumn",
            temp: "12-18°C",
            event: "Fireside Gathering",
            assetName: "Red-shirtCheck",
            isFavorite: true
        ),
        ProductCardItem(
            name: "Slate Minimalist Crewneck",
            category: "Modern Basic",
            rating: "4.8",
            description: "The quintessential everyday luxury tee. Tailored from ultra-soft heavyweight pima cotton jersey in a versatile charcoal slate colorway, featuring a structured crew collar.",
            weather: "Sunny / Mild",
            temp: "20-28°C",
            event: "Casual Outing",
            assetName: "T-Shirt",
            isFavorite: false
        ),
        ProductCardItem(
            name: "Sage Alpine Longsleeve",
            category: "Active Outdoor",
            rating: "4.9",
            description: "Crafted from breathable merino tech knit in a calming sage forest hue. Designed with articulated full-length sleeves and thermal insulation for mountain trail hikes.",
            weather: "Breezy / Spring",
            temp: "15-22°C",
            event: "Trail Hike",
            assetName: "Green-FullSleeve",
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
