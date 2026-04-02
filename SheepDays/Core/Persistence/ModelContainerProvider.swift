//
//  ModelContainerProvider.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation
import SwiftData

enum ModelContainerProvider {
    static let shared: ModelContainer = makeModelContainer(isStoredInMemoryOnly: false)

    static func makePreviewContainer() -> ModelContainer {
        makeModelContainer(isStoredInMemoryOnly: true)
    }
}

private extension ModelContainerProvider {
    static func makeModelContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        let schema = Schema([
            Event.self,
            Notebook.self,
            Tag.self
        ])
        let configuration = ModelConfiguration(
            "SheepDays",
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }
}
