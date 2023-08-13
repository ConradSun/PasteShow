//
//  MainView.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/12.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var info: CopiedInfo
    
    var body: some View {
        NavigationSplitView(sidebar: {
            List(info.copiedItems, id: \.self) { item in
                Section("CopiedItem") {
                    ForEach(item.keys.sorted(), id: \.self) { key in
                        NavigationLink {
                            ContentsView(itemType: key, itemData: item[key]!)
                                .navigationTitle(key)
                        } label: {
                            Text(key)
                                .contextMenu {
                                    Button("Copy Data Type") {
                                        PasteboardManager.shared.setDataWithoutReserve(data: key, forType: .string)
                                    }
                                    Button("Remove This Type") {
                                        PasteboardManager.shared.removeDataWithReserve(data: item[key]!, forType: key)
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom, alignment: .leading) {
                if info.sourceURL != nil {
                    VStack(alignment: .leading) {
                        Section {
                            Label {
                                let name = info.sourceURL!.lastPathComponent
                                Text(name.replacingOccurrences(of: ".app", with: ""))
                                    .lineLimit(1)
                            } icon: {
                                let path = info.sourceURL!.path().removingPercentEncoding
                                Image(nsImage: NSWorkspace.shared.icon(forFile: path!))
                                    .frame(height: 18)
                            }
                        } header: {
                            Text("Source")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
        }, detail: {
        })
        
        .padding()
        .frame(minWidth: CGFloat(600), minHeight: CGFloat(360))
    }
}

//#Preview {
//    MainView()
//}
