//
//  ContentsView.swift
//  PasteShow
//
//  Created by ConradSun on 2023/8/12.
//

import SwiftUI
import QuickLookUI
import UniformTypeIdentifiers

struct ContentsView: View {
    @EnvironmentObject var status: NavigationStatus
    let itemType: String
    let itemData: Data
    
    func updateStatus(title: String, subtitle: String) {
        status.titleString = title
        status.subtitleString = subtitle
    }
    
    func getPlainTextView(text: String?) -> some View {
        GeometryReader { geometry in
            if let text = text {
                Text(text)
                    .padding(.leading, 4)
                Spacer()
                    .frame(width: geometry.size.width)
            } else {
                Text("Unable to display text")
            }
        }
        .onAppear {
            updateStatus(title: itemType, subtitle: "\(itemData.count.formatted(.byteCount(style: .file)))")
        }
    }
    
    func getRichTextView(attrText: NSAttributedString) -> some View {
        RichTextView(attrText: attrText)
            .onAppear {
                updateStatus(title: itemType, subtitle: "\(itemData.count.formatted(.byteCount(style: .file)))")
            }
    }

    var body: some View {
        let utType = UTType(itemType) ?? .plainText
        switch utType {
        case .utf8PlainText, .fileURL:
            getPlainTextView(text: String(data: itemData, encoding: .utf8)!)
        case .utf16ExternalPlainText:
            getPlainTextView(text: String(data: itemData, encoding: .utf16)!)
        case .rtf:
            getRichTextView(attrText: NSAttributedString(rtf: itemData, documentAttributes: nil)!)
        case .rtfd:
            getRichTextView(attrText: NSAttributedString(rtfd: itemData, documentAttributes: nil)!)
        case .flatRTFD:
            getRichTextView(attrText: NSAttributedString(rtfd: itemData, documentAttributes: nil)!)
        case .html:
            getRichTextView(attrText: NSAttributedString(html: itemData, documentAttributes: nil)!)
        case .png, .jpeg, .tiff, .bmp, .gif, .webP:
            let image = NSImage(data: itemData)!
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: image.size.width, maxHeight: image.size.height)
                .onAppear {
                    updateStatus(title: itemType, subtitle: "\(Int(image.size.width)) * \(Int(image.size.height)) pixel")
                }
        default:
            QuickLookView(data: itemData, type: utType)
                .onAppear {
                    updateStatus(title: itemType, subtitle: "")
                }
        }
    }
}

struct RichTextView: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    let attrText: NSAttributedString
    
    func makeNSView(context: Context) -> NSViewType {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.textStorage?.setAttributedString(attrText)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        let textView = nsView.documentView as! NSTextView
        textView.textStorage?.setAttributedString(attrText)
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
