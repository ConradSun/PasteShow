//
//  App.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/12.
//

import SwiftUI

@main
struct PasteShowApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(PasteboardManager.shared.pasteInfo)
        }
    }
}
