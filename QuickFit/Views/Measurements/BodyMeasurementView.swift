//
//  BodyMeasurementView.swift
//  QuickFit
//

import SwiftData
import SwiftUI

struct BodyMeasurementView: View {
    @Query(sort: \BodyMeasurement.capturedAt, order: .reverse) private var measurements: [BodyMeasurement]
    @State private var viewModel = MeasurementViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                List {
                    if let latest = measurements.first {
                        Section("Live Proportions (Vision Estimated)") {
                            LabeledContent("Estimated Height", value: String(format: "%.1f cm", latest.estimatedHeight))
                            LabeledContent("Shoulder Width", value: String(format: "%.1f cm", latest.shoulderWidth))
                            LabeledContent("Hip Width", value: String(format: "%.1f cm", latest.hipWidth))
                            LabeledContent("Torso Height", value: String(format: "%.1f cm", latest.torsoHeight))
                            LabeledContent("Shoulder-to-Hip Ratio", value: String(format: "%.2f", latest.shoulderToHipRatio))
                        }
                        .listRowBackground(Color.white.opacity(0.08))
                        .foregroundStyle(.white)
                    } else {
                        ContentUnavailableView(
                            "No Stats Captured",
                            systemImage: "figure.stand",
                            description: Text("Open Try-On camera and stand back to calculate body landmarks.")
                        )
                        .foregroundStyle(.white)
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Measurements")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    BodyMeasurementView()
}
