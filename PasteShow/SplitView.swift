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

    var body: some View {
        if info.infoList.isEmpty || info.infoList[0].copiedItems.isEmpty {
            Text("No Item")
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

    func setupIndex() -> (Int, Int) {
        if status.setIndex >= info.infoList.count {
            return (-1, -1)
        }
        
        var sectionIndex = -1
        var itemIndex = -1
        var count = 0
        var index = 0
        
        for items in info.infoList[status.setIndex].copiedItems {
            if status.itemIndex < count + items.count {
                sectionIndex = index
                itemIndex = status.itemIndex - count
                break
            }
            count = count + items.count
            index = index + 1
        }
        
        return (sectionIndex, itemIndex)
    }

    var body: some View {
        let (sectionIndex, itemIndex) = setupIndex()
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
        if !info.infoList.isEmpty {
            let appUrl = info.infoList[status.setIndex].sourceURL!
            VStack(alignment: .leading) {
                Section {
                    Label {
                        let name = appUrl.lastPathComponent
                        Text(name.replacingOccurrences(of: ".app", with: ""))
                            .lineLimit(1)
                    } icon: {
                        let path = appUrl.path().removingPercentEncoding
                        Image(nsImage: NSWorkspace.shared.icon(forFile: path!))
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
        Picker(selection: $info.boardType) {
            ForEach(Array(PasteboardType.allCases.enumerated()), id: \.1.rawValue) { index, type in
                Text(type.rawValue)
            }
        } label: {
            Text("\(info.boardType)")
        }
        .onReceive(info.$boardType) { type in
            PasteboardManager.shared.setupPasteboardType(type: type)
        }
    }
}
