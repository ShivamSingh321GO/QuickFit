//
//  WelcomeView.swift
//  QuickFit
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @State private var animateItems = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "0C0A12"),
                    Color(hex: "1F142E"),
                    Color(hex: "08060A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            glowView(color: Color("AccentColor").opacity(0.12), radius: 150)
                .offset(x: -120, y: -200)
            glowView(color: Color.purple.opacity(0.15), radius: 200)
                .offset(x: 150, y: 150)
            
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Text("QuickFit")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                    
                    Text("Try-on clothes virtually and create avatars")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.vertical, 40)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("AccentColor"), in: Capsule())
                        .shadow(color: Color("AccentColor").opacity(0.25), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            Group {
                floatingGarment(name: "Blue-shirt", size: 90, rotation: -12)
                    .offset(x: -130, y: -260 + (animateItems ? 8 : -8))
                
                floatingGarment(name: "Green-FullSleeve", size: 100, rotation: 10)
                    .offset(x: 120, y: -230 + (animateItems ? -6 : 6))
                
                floatingGarment(name: "Green-Shirt", size: 85, rotation: 5)
                    .offset(x: -110, y: 100 + (animateItems ? -8 : 8))
                
                floatingGarment(name: "Red-shirtCheck", size: 85, rotation: -8)
                    .offset(x: -130, y: 210 + (animateItems ? 6 : -6))
                
                floatingGarment(name: "T-Shirt", size: 90, rotation: -5)
                    .offset(x: 120, y: 170 + (animateItems ? 8 : -8))
            }
            
            Group {
                Image(systemName: "sparkle")
                    .font(.system(size: 28, weight: .thin))
                    .foregroundStyle(.white.opacity(0.8))
                    .rotationEffect(.degrees(animateItems ? 45 : 0))
                    .offset(x: -30, y: -280)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 22))
                    .foregroundStyle(Color("AccentColor").opacity(0.85))
                    .rotationEffect(.degrees(animateItems ? -20 : 10))
                    .offset(x: 100, y: -310 + (animateItems ? -5 : 5))
                
                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .rotationEffect(.degrees(animateItems ? 30 : -10))
                    .offset(x: -80, y: -80 + (animateItems ? 4 : -4))
                
                Image(systemName: "sparkle")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.7))
                    .rotationEffect(.degrees(animateItems ? -15 : 15))
                    .offset(x: 130, y: 70 + (animateItems ? 6 : -6))
                
                Image(systemName: "crystalball")
                    .font(.system(size: 24))
                    .foregroundStyle(.purple.opacity(0.7))
                    .offset(x: 70, y: 40 + (animateItems ? -4 : 4))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                animateItems = true
            }
        }
    }
    
    private func glowView(color: Color, radius: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: radius, height: radius)
            .blur(radius: 60)
    }
    
    private func floatingGarment(name: String, size: CGFloat, rotation: Double) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
    }
}

#Preview {
    WelcomeView()
}
