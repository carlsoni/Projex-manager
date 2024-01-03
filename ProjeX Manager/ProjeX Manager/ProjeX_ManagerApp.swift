//
//  ProjeX_ManagerApp.swift
//  ProjeX Manager
//
//  Created by Ian Carlson on 11/20/23.
//

import SwiftUI

@main
struct ProjeX_ManagerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
