//
//  PasteboardManager.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/12.
//

import AppKit
import Foundation

class CopiedInfo: ObservableObject, Identifiable {
    @Published var changeCount = 0
    @Published var sourceURL = URL(string: "")
    @Published var copiedItems = [[String: Data]]()
}

class PasteboardManager {
    static let shared = PasteboardManager()
    var copiedInfo = CopiedInfo()
    private let pasteboard = NSPasteboard.general
    private var observerTimer = Timer()
    
    private init() {
        setupObserverTimer()
    }
    
    private func setupObserverTimer() {
        observerTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { [self] _ in
            guard copiedInfo.changeCount != pasteboard.changeCount else {
                return
            }
            
            onPasteboardChanged()
        })
    }
    
    private func onPasteboardChanged() {
        copiedInfo.copiedItems.removeAll()
        copiedInfo.changeCount = pasteboard.changeCount
        
        guard pasteboard.pasteboardItems != nil else {
            return
        }
        
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            copiedInfo.sourceURL = frontApp.bundleURL
        }
        
        for item in pasteboard.pasteboardItems! {
            var itemInfo = [String: Data]()
            
            for type in item.types {
                if let value = item.data(forType: type) {
                    itemInfo[type.rawValue] = value
                }
            }
            copiedInfo.copiedItems.append(itemInfo)
        }
    }
    
    func setDataWithoutReserve(data: String, forType type: NSPasteboard.PasteboardType) {
        pasteboard.clearContents()
        pasteboard.setString(data, forType: type)
    }
    
    func removeDataWithReserve(data: Data, forType type: String) {
        var pasteItems = [NSPasteboardItem]()
        pasteboard.clearContents()
        for items in copiedInfo.copiedItems {
            let pasteItem = NSPasteboardItem()
            for pair in items {
                if pair.key == type && pair.value == data {
                    continue
                }
                pasteItem.setData(pair.value, forType: NSPasteboard.PasteboardType(pair.key))
            }
            pasteItems.append(pasteItem)
        }
        pasteboard.writeObjects(pasteItems)
    }
}
