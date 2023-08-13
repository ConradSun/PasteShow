//
//  App.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/12.
//

import SwiftUI

@main
struct PasteShowApp: App {
    let manager = PasteboardManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(manager.copiedInfo)
        }
    }
}
