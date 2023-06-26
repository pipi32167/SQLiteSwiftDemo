//
//  SQLiteSwiftDemoApp.swift
//  SQLiteSwiftDemo
//
//  Created by Trillion Young on 2023/6/26.
//

import SwiftUI

@main
struct SQLiteSwiftDemoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
