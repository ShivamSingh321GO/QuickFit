//
//  Avatar.swift
//  QuickFit
//

import Foundation
import SwiftData

@Model
final class Avatar {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var styleName: String
    var creationFlow: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        imageData: Data,
        styleName: String = "Original",
        creationFlow: String = "Photo",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imageData = imageData
        self.styleName = styleName
        self.creationFlow = creationFlow
        self.createdAt = createdAt
    }
}
