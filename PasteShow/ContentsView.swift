//
//  ContentsView.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/12.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentsView: View {
    let itemType: String
    let itemData: Data

    var body: some View {
        if let image = NSImage(data: itemData) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: image.size.width, maxHeight: image.size.height)
                .navigationSubtitle("\(Int(image.size.width)) * \(Int(image.size.height)) pixel")
        } else {
            CopiedTextView(itemType: itemType, itemData: itemData)
                .navigationSubtitle("\(itemData.count.formatted(.byteCount(style: .file)))")
        }
    }
}

struct CopiedTextView: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    
    let itemType: String
    let itemData: Data
    
    func updateTextView(textView: UnsafePointer<NSTextView>) {
        var plainText = String()
        var attrText = NSAttributedString()
        let contentType = UTType(itemType) ?? .plainText
        
        switch contentType {
        case .utf8PlainText, .html:
            plainText = String(data: itemData, encoding: .utf8) ?? "No Preview"
        case .utf16ExternalPlainText:
            plainText = String(data: itemData, encoding: .utf16) ?? "No Preview"
        case .rtf, .rtfd, .flatRTFD:
            attrText = NSAttributedString(rtf: itemData, documentAttributes: nil)
            ?? NSAttributedString(rtfd: itemData, documentAttributes: nil)!
            
        case .fileURL, .url:
            plainText = String(data: itemData, encoding: .utf8) ?? "No Preview"
            
        default:
            plainText = "No Preview"
        }
        
        if !attrText.string.isEmpty {
            textView.pointee.textStorage?.setAttributedString(attrText)
        } else {
            textView.pointee.textStorage?.setAttributedString(attrText)
            textView.pointee.string = plainText
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
