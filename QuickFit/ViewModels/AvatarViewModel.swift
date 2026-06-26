//
//  AvatarViewModel.swift
//  QuickFit
//

import SwiftUI
import Observation

@Observable
final class AvatarViewModel {
    var selectedCreationFlow: String = "Photo"
    let creationFlows: [String] = ["Photo", "Skeleton"]
    var selectedFilterStyle: String = "Original"
    let filterStyles: [String] = ["Original", "Sketch", "Cartoon", "Noir", "Vivid"]
    var isShowingCreationFlow: Bool = false
    var selectedAvatar: Avatar?
    
    func startCreation(flow: String) {
        selectedCreationFlow = flow
        isShowingCreationFlow = true
    }
}
