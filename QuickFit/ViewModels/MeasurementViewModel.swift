//
//  MeasurementViewModel.swift
//  QuickFit
//

import SwiftUI
import Observation

@Observable
final class MeasurementViewModel {
    var latestMeasurement: BodyMeasurement?
    var isShowingPanel: Bool = false
    
    var formattedHeight: String {
        guard let height = latestMeasurement?.estimatedHeight, height > 0 else {
            return "-- cm"
        }
        return String(format: "%.1f cm", height)
    }
}
