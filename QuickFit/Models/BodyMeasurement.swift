//
//  BodyMeasurement.swift
//  QuickFit
//

import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var id: UUID
    var shoulderWidth: Double
    var hipWidth: Double
    var torsoHeight: Double
    var estimatedHeight: Double
    var capturedAt: Date
    
    var shoulderToHipRatio: Double {
        guard hipWidth > 0 else { return 1.0 }
        return shoulderWidth / hipWidth
    }
    
    init(
        id: UUID = UUID(),
        shoulderWidth: Double = 0.0,
        hipWidth: Double = 0.0,
        torsoHeight: Double = 0.0,
        estimatedHeight: Double = 0.0,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.shoulderWidth = shoulderWidth
        self.hipWidth = hipWidth
        self.torsoHeight = torsoHeight
        self.estimatedHeight = estimatedHeight
        self.capturedAt = capturedAt
    }
}
