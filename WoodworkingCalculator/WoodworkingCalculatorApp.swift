//
//  WoodworkingCalculatorApp.swift
//  WoodworkingCalculator
//
//  Created by Sean Kelley on 2025-07-02.
//

import SwiftUI

@main
struct WoodworkingCalculatorApp: App {
    @AppStorage(Constants.AppStorage.themeKey)
    private var theme = Constants.AppStorage.themeDefault

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(theme.colorScheme)
        }
    }
}
