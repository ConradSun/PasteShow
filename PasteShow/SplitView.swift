//
//  HistoryView.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/22.
//

import SwiftUI

class NavigationStatus: ObservableObject {
    @Published var setIndex = 0
    @Published var itemIndex = 0
    @Published var titleString = ""
    @Published var subtitleString = ""
}

struct SidebarView: View {
    @EnvironmentObject var info: PasteInfoList
    @EnvironmentObject var status: NavigationStatus
    
    var body: some View {
        List(0 ..< info.infoList.count, id: \.self, selection: $status.setIndex) { index in
            Text("Items \(index+1) -> \(info.infoList[index].itemType.rawValue)")
                .contextMenu {
                    if index > 0 {
                        Button("Set to Current") {
                            status.setIndex = 0
                            PasteboardManager.shared.refreshPasteItems(itemsIndex: index)
                        }
                        Button("Remove this item") {
                            if status.setIndex >= index {
                                status.setIndex = max(0, status.setIndex - 1)
                            }
                            PasteboardManager.shared.removePasteItem(itemsIndex: index)
                        }
                    }
                }
        }
        .toolbar {
            PickerView()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var info: PasteInfoList
    @EnvironmentObject var status: NavigationStatus
    
    func getTagBase(sectionIndex: Int) -> Int {
        var count = 0
        for i in 0 ..< sectionIndex {
            count = count + info.infoList[status.setIndex].copiedItems[i].count
        }
        
        return count
    }
    
    func resetStatus() {
        status.setIndex = 0
        status.itemIndex = 0
        status.titleString = ""
        status.subtitleString = ""
    }

    var body: some View {
        if info.infoList.isEmpty {
            Text("No Item")
                .onAppear {
                    resetStatus()
                }
        } else {
            let items = info.infoList[status.setIndex].copiedItems
            List(0 ..< items.count, id: \.self, selection: $status.itemIndex) { index in
                Section("Section \(index+1)") {
                    let tagBase = getTagBase(sectionIndex: index)
                    let types = items[index].keys.sorted()
                    ForEach(0 ..< types.count, id: \.self) { i in
                        Text(types[i])
                            .tag(tagBase+i)
                            .lineLimit(1)
                            .contextMenu {
                                Button("Copy Data Type") {
                                    status.itemIndex = 0
                                    PasteboardManager.shared.setDataWithoutReserve(data: types[i], forType: .string)
                                }
                            }
                    }
                }
            }
            .navigationTitle(status.titleString)
            .navigationSubtitle(status.subtitleString)
        }
    }
}

struct DetailView: View {
    @EnvironmentObject var info: PasteInfoList
    @EnvironmentObject var status: NavigationStatus

    func calculateSectionAndItemIndex() -> (sectionIndex: Int, itemIndex: Int) {
        let items = info.infoList[safe: status.setIndex]?.copiedItems ?? []
        var count = 0
        
        for (index, sectionItems) in items.enumerated() {
            let newCount = count + sectionItems.count
            if status.itemIndex < newCount {
                return (index, status.itemIndex - count)
            }
            count = newCount
        }
        
        return (-1, -1)
    }

    var body: some View {
        let (sectionIndex, itemIndex) = calculateSectionAndItemIndex()
        if sectionIndex == -1 || itemIndex == -1 {
            Text("No Preview")
        } else {
            let items = info.infoList[status.setIndex].copiedItems[sectionIndex]
            let type = items.keys.sorted()[itemIndex]
            ContentsView(itemType: type, itemData: items[type]!)
        }
    }
}

struct SourceView: View {
    @EnvironmentObject var info: PasteInfoList
    @EnvironmentObject var status: NavigationStatus
    
    var body: some View {
        if let appUrl = info.infoList[safe: status.setIndex]?.sourceURL,
           let path = appUrl.path.removingPercentEncoding {
            VStack(alignment: .leading) {
                Section {
                    Label {
                        let name = appUrl.lastPathComponent
                        Text(name.replacingOccurrences(of: ".app", with: ""))
                            .lineLimit(1)
                    } icon: {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                            .frame(height: 18)
                    }
                } header: {
                    Text("Source")
                }
            }
        }
    }
}

struct PickerView: View {
    @EnvironmentObject var info: PasteInfoList
    
    var body: some View {
        Picker("Select Type", selection: $info.boardType) {
            ForEach(Array(PasteboardType.allCases.enumerated()), id: \.1.rawValue) { index, type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onReceive(info.$boardType) { type in
            PasteboardManager.shared.setupPasteboardType(type: type)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
