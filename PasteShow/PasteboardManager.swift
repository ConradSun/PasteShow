//
//  PasteboardManager.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/12.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

enum ItemType: String {
    case Text = "Text"
    case HTML = "HTML"
    case File = "File"
    case Image = "Image"
    case URL = "URL"
    case Other = "Other"
}

enum PasteboardType: String, CaseIterable {
    case General = "General"
    case Drag = "Drag"
}

class PasteInfoList: ObservableObject {
    struct PasteInfo {
        var itemType = ItemType.Other
        var sourceURL = URL(string: "")
        var copiedItems = [[String: Data]]()
    }
    
    @Published var boardType = "General"
    @Published var infoList = [PasteInfo]()
    
    func appendInfo(source: URL, items: [[String: Data]], type: ItemType) {
        var info = PasteInfo()
        info.sourceURL = source
        info.copiedItems = items
        info.itemType = type
        infoList.insert(info, at: 0)
    }
}

class PasteboardManager {
    static let shared = PasteboardManager()
    var changeCount = 0
    var pasteInfo = PasteInfoList()
    
    private var pasteboard = NSPasteboard.init(name: .general)
    private var observerTimer = Timer()
    
    private init() {
        setupPasteboardType(type: pasteInfo.boardType)
    }
    
    private func setupObserverTimer() {
        observerTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { [self] _ in
            guard changeCount != pasteboard.changeCount else {
                return
            }
            
            onPasteboardChanged()
        })
    }
    
    private func onPasteboardChanged() {
        var sourceURL = URL(string: "")
        var copiedItems = [[String: Data]]()
        var itemType = ItemType.Other
        
        changeCount = pasteboard.changeCount
        guard pasteboard.pasteboardItems != nil else {
            return
        }
        
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            sourceURL = frontApp.bundleURL
        }
        
        let pasteType = pasteboard.pasteboardItems?.first?.types.first?.rawValue
        let utType = UTType(pasteType ?? "public.item") ?? .item
        
        switch utType {
        case .text, .plainText, .rtf, .rtfd, .utf8PlainText:
            itemType = .Text
        case .html:
            itemType = .HTML
        case .image, .png, .jpeg, .tiff, .bmp, .gif, .webP:
            itemType = .Image
        case .url:
            itemType = .URL
        case .fileURL:
            itemType = .File
        default:
            itemType = .Other
        }
        
        for item in pasteboard.pasteboardItems! {
            var itemInfo = [String: Data]()
            
            for type in item.types {
                if let value = item.data(forType: type) {
                    itemInfo[type.rawValue] = value
                }
            }
            copiedItems.append(itemInfo)
        }
        pasteInfo.appendInfo(source: sourceURL!, items: copiedItems, type: itemType)
    }
    
    private func getBoardType(_ type: String) -> NSPasteboard.Name {
        let pasteboardType = ["General": NSPasteboard.Name.general,
                              "Drag": NSPasteboard.Name.drag,
                              "Font": NSPasteboard.Name.font]
        
        guard let name = pasteboardType[type] else {
            return .general
        }
        return name
    }
    
    func setupPasteboardType(type: String) {
        let boardType = getBoardType(type)
        pasteInfo.infoList.removeAll()
        print("setup \(boardType)")
        pasteboard = NSPasteboard.init(name: boardType)
        setupObserverTimer()
    }
    
    func setDataWithoutReserve(data: String, forType type: NSPasteboard.PasteboardType) {
        pasteboard.clearContents()
        pasteboard.setString(data, forType: type)
    }
    
    func refreshPasteItems(itemsIndex: Int) {
        var pasteItems = [NSPasteboardItem]()
        pasteboard.clearContents()
        
        for items in pasteInfo.infoList[itemsIndex].copiedItems {
            let pasteItem = NSPasteboardItem()
            for pair in items {
                pasteItem.setData(pair.value, forType: NSPasteboard.PasteboardType(pair.key))
            }
            pasteItems.append(pasteItem)
        }
        pasteInfo.infoList.remove(at: itemsIndex)
        pasteboard.writeObjects(pasteItems)
    }
    
    func removePasteItem(itemsIndex: Int) {
        pasteInfo.infoList.remove(at: itemsIndex)
    }
}
