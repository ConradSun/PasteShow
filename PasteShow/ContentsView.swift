//
//  ContentsView.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/12.
//

import SwiftUI
import QuickLookUI
import UniformTypeIdentifiers

enum ContentsType {
    case UTF8Text
    case UTF16Text
    case RTFText
    case HTMLText
    case Image
    case Other
}

struct ContentsView: View {
    let itemType: String
    let itemData: Data
    let utType: UTType

    init(itemType: String, itemData: Data) {
        self.itemType = itemType
        self.itemData = itemData
        self.utType = UTType(itemType) ?? .plainText
    }
    
    func getContentsType(itemType: String) -> ContentsType {
        var contentsType = ContentsType.UTF8Text
        
        switch utType {
        case .utf8PlainText, .url:
            contentsType = .UTF8Text
        case .utf16ExternalPlainText:
            contentsType = .UTF16Text
        case .rtf, .rtfd, .flatRTFD:
            contentsType = .RTFText
        case .html:
            contentsType = .HTMLText
        case .image:
            contentsType = .Image      
        default:
            contentsType = .Other
        }
        
        return contentsType
    }

    var body: some View {
        let contentsType = getContentsType(itemType: itemType)
        switch contentsType {
        case .UTF8Text, .UTF16Text, .RTFText, .HTMLText:
            CopiedTextView(textType: contentsType, textData: itemData)
                .navigationSubtitle("\(itemData.count.formatted(.byteCount(style: .file)))")
        case .Image:
            let image = NSImage(data: itemData)!
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: image.size.width, maxHeight: image.size.height)
                .navigationSubtitle("\(Int(image.size.width)) * \(Int(image.size.height)) pixel")
        default:
            QuickLookView(data: itemData, type: utType)
        }
    }
}

struct CopiedTextView: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    
    let textType: ContentsType
    let textData: Data
    
    func updateTextView(textView: UnsafePointer<NSTextView>) {
        textView.pointee.textStorage?.setAttributedString(NSAttributedString())
        
        switch textType {
        case .UTF8Text:
            textView.pointee.string = String(data: textData, encoding: .utf8)
            ?? "No Preview"
        case .UTF16Text:
            textView.pointee.string = String(data: textData, encoding: .utf16)
            ?? "No Preview"
        case .RTFText:
            let attrText = NSAttributedString(rtf: textData, documentAttributes: nil)
            ?? NSAttributedString(rtfd: textData, documentAttributes: nil)!
            textView.pointee.textStorage?.setAttributedString(attrText)
        case .HTMLText:
            let attrText = NSAttributedString(html: textData, documentAttributes: nil)!
            textView.pointee.textStorage?.setAttributedString(attrText)
        default:
            textView.pointee.string = "No Preview"
        }
    }
    
    func makeNSView(context: Context) -> NSViewType {
        let scrollView = NSTextView.scrollableTextView()
        var textView = scrollView.documentView as! NSTextView
        
        updateTextView(textView: &textView)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        var textView = nsView.documentView as! NSTextView
        
        updateTextView(textView: &textView)
    }
}

struct QuickLookView: NSViewRepresentable {
    typealias NSViewType = QLPreviewView
    let previewItem: QLPreviewItem
    
    init(data: Data, type: UTType) {
        guard let tmpDir = try? FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: FileManager.default.homeDirectoryForCurrentUser,
            create: true) else {
            previewItem = NSURL()
            return
        }
        
        let fileUrl = tmpDir.appendingPathComponent("data", conformingTo: type)
        guard ((try? data.write(to: fileUrl)) != nil) else {
            previewItem = NSURL()
            return
        }
        
        previewItem = fileUrl as NSURL
    }
    
    func makeNSView(context: Context) -> NSViewType {
        let nsView = NSViewType()
        nsView.previewItem = previewItem
        return nsView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.previewItem = previewItem
    }
}
