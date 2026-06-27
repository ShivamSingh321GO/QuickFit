//
//  GarmentDetailView.swift
//  QuickFit
//

import SwiftUI

struct GarmentDetailView: View {
    let name: String
    let category: String
    let rating: String
    let description: String
    let weather: String
    let temp: String
    let event: String
    let assetName: String
    let gradientIndex: Int
    
    @State private var isFavorite: Bool = false
    @State private var isShowingTryOn: Bool = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero Image Studio Container
                    ZStack {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(premiumDetailGradient)
                            .aspectRatio(0.9, contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                        
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .padding(24)
                            .shadow(color: .black.opacity(0.4), radius: 15, y: 15)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Title & Description Block
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category.uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AccentColor"))
                                .tracking(1)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(rating)
                                    .fontWeight(.bold)
                            }
                            .font(.footnote)
                            .foregroundStyle(.white)
                        }
                        
                        Text(name)
                            .font(.system(.title, design: .default).weight(.heavy))
                            .foregroundStyle(.white)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(4)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    
                    // Metadata Attributes Pills Row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            attributePill(title: "Weather", value: weather)
                            attributePill(title: "Temp.", value: temp)
                            attributePill(title: "Event", value: event)
                            attributePill(title: "Fit", value: "Tailored Luxe")
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 100) // space for bottom action bar
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Native Bottom Accent Button
            Button {
                isShowingTryOn = true
            } label: {
                Text("Try me")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("AccentColor"), in: Capsule())
                    .shadow(color: Color("AccentColor").opacity(0.5), radius: 12, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        isFavorite.toggle()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : .white)
                    }
                    
                    Button {
                        // edit
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.white)
                    }
                    
                    Button {
                        // share
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingTryOn) {
            CameraView(tryOnAssetName: assetName)
        }
    }
    
    private func attributePill(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text("\(title):")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.1), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
    }
    
    private var premiumDetailGradient: LinearGradient {
        let palettes = [
            [Color(hex: "2C3E50"), Color(hex: "1A252F")],
            [Color(hex: "4A233E"), Color(hex: "2E1426")],
            [Color(hex: "1F3A3D"), Color(hex: "122224")],
            [Color(hex: "34234A"), Color(hex: "1E142B")],
            [Color(hex: "4A3623"), Color(hex: "2B1F14")],
            [Color(hex: "4A2328"), Color(hex: "2B1417")]
        ]
        let chosen = palettes[abs(gradientIndex) % palettes.count]
        return LinearGradient(colors: chosen, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    NavigationStack {
        GarmentDetailView(
            name: "Wet Weather Elegance",
            category: "Cozy Wear",
            rating: "4.8",
            description: "Experience premium comfort and effortless protection against the elements.",
            weather: "Rainy / Autumn",
            temp: "16-22°C",
            event: "Promenade",
            assetName: "Versity-Jacket",
            gradientIndex: 2
        )
    }
}
