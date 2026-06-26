//
//  Garment.swift
//  QuickFit
//

import Foundation
import SwiftData

@Model
final class Garment {
    var id: UUID
    var name: String
    var assetName: String?
    @Attribute(.externalStorage) var imageData: Data?
    var isBundled: Bool
    var category: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        assetName: String? = nil,
        imageData: Data? = nil,
        isBundled: Bool = false,
        category: String = "Tops",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.assetName = assetName
        self.imageData = imageData
        self.isBundled = isBundled
        self.category = category
        self.createdAt = createdAt
    }
}
