//
//  MainView.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/12.
//

import SwiftUI

struct MainView: View {
    @StateObject var status = NavigationStatus()
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            ContentView()
                .safeAreaInset(edge: .bottom, alignment: .leading) {
                    SourceView()
                        .padding()
                }
        } detail: {
            DetailView()
        }
        .padding()
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: CGFloat(600), minHeight: CGFloat(360))
        .environmentObject(status)
    }
}

#Preview {
    MainView()
        .environmentObject(PasteboardManager.shared.pasteInfo)
}
