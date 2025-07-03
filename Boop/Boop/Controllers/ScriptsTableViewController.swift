//
//  ScriptsTableViewController.swift
//  Boop
//
//  Created by Ivan on 2/13/19.
//  Copyright © 2019 OKatBest. All rights reserved.
//

import Cocoa

class ScriptsTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var tableView: ScriptTableView!
    
    var results: [Script] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return results.count
    }
    
    private func scriptIcon(identifier: String?, interpreter: ScriptInterpreter) -> NSImage? {
        var base: NSImage?
        if let id = identifier {
            if let named = NSImage(named: "icons8-\(id)") {
                base = named
            } else if #available(macOS 11.0, *),
                      let system = NSImage(systemSymbolName: id, accessibilityDescription: nil) {
                base = system
            }
        }
        base = base ?? NSImage(named: "icons8-unknown")

        guard let image = base else { return nil }

        let size = image.size
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))

        let label = interpreter.shortName as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.6)
        ]
        let textSize = label.size(withAttributes: attrs)
        let rect = NSRect(x: size.width - textSize.width - 2, y: 0, width: textSize.width, height: textSize.height)
        label.draw(in: rect, withAttributes: attrs)
        newImage.unlockFocus()
        return newImage
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {        
        
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "scriptCell"), owner: self) as! ScriptTableViewCell
        
        guard let script = scriptAt(row) else {
            fatalError("Missing script for index \(row).")
        }
        
        view.titleLabel.stringValue = script.name ?? "No Name 🤔"

        var subtitle = script.desc ?? "No Description 😢"
        if let cats = script.categories, !cats.isEmpty {
            let display = cats.map { $0.capitalized }.joined(separator: " · ")
            subtitle += " \u2022 " + display
        }
        view.subtitleLabel.stringValue = subtitle
        
        view.imageView?.image = self.scriptIcon(identifier: script.icon, interpreter: script.interpreter)
        
        return view
        
    }
    
    func scriptAt(_ index: Int) -> Script? {
        guard index < results.count else {
            return nil
        }
        return results[index]
    }
    
    var selectedScript:Script? {
        guard tableView.selectedRow >= 0 else {
            // Nothing selected, return first item
            return scriptAt(0)
        }
        return scriptAt(tableView.selectedRow)
    }
}
