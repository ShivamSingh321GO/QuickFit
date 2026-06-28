//
//  HomeView.swift
//  QuickFit
//

import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WardrobeView()
                .tabItem {
                    Label("Wardrobe", systemImage: "tshirt")
                }
                .tag(0)
            
            CreationsView()
                .tabItem {
                    Label("Creations", systemImage: "sparkles.rectangle.stack.fill")
                }
                .tag(1)
            
            AvatarView()
                .tabItem {
                    Label("Avatars", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .tint(Color("AccentColor"))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    HomeView()
}
