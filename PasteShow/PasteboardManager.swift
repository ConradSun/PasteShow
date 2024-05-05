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
    
    @Published var boardType = PasteboardType.General
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
    
    private var pasteboard = NSPasteboard.general
    private var observerTimer = Timer()
    
    private init() {
        setupPasteboardType(type: pasteInfo.boardType)
    }
    
    deinit {
        observerTimer.invalidate()
    }
    
    private func setupObserverTimer() {
        observerTimer.invalidate()
        observerTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard self?.changeCount != self?.pasteboard.changeCount else {
                return
            }
            self?.onPasteboardChanged()
        }
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
    
    func setupPasteboardType(type: PasteboardType) {
        pasteboard = NSPasteboard(name: type.pasteboardName)
        pasteInfo.infoList.removeAll()
        print("setup \(type.rawValue)")
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

extension PasteboardType {
    var pasteboardName: NSPasteboard.Name {
        switch self {
        case .General:
            return .general
        case .Drag:
            return .drag
        }
    }
}
