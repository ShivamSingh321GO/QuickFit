//
//  QuickFitApp.swift
//  QuickFit
//
//  Created by shivam kumar singh on 6/26/26.
//

import SwiftUI
import SwiftData

@main
struct QuickFitApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Garment.self,
            Avatar.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Auto-recovery during dev: If migration fails due to schema changes, wipe old store and retry
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-shm"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-wal"))
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                WelcomeView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
