//
//  FinanceApp.swift
//  Finance
//
//  Created by Хамза Кабылбек on 11.12.2024.
//

import SwiftUI

@main
struct FinanceApp: App {
    @StateObject private var store = TransactionStore()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    
//    init() {
//        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
//    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
