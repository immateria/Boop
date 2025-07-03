//
//  AppDelegate.swift
//  Boop
//
//  Created by Ivan on 1/26/19.
//  Copyright © 2019 OKatBest. All rights reserved.
//

import Cocoa
import SavannaKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var openPickerMenuItem: NSMenuItem!
    @IBOutlet weak var closePickerMenuItem: NSMenuItem!
    
    @IBOutlet weak var popoverViewController: PopoverViewController!
    @IBOutlet weak var scriptManager: ScriptManager!
    @IBOutlet weak var editor: SyntaxTextView!

    /// Currently edited script file, if any
    private var editingScriptURL: URL?

    // Frame auto save name for app window frame restoration.
    private static let appWindowName = "boop.app.window"
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        ThemeSettingsViewController.applyTheme()
        
        NSWindow.allowsAutomaticWindowTabbing = false
        NSApp.servicesProvider = self
        
        // Restore app window frame.
        window.setFrameUsingName(AppDelegate.appWindowName)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Memorize app window frame for restoration.
        window.saveFrame(usingName: AppDelegate.appWindowName)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func showPreferencesWindow(_ sender: NSMenuItem) {
        let controller = NSStoryboard.init(name: "Preferences", bundle: nil).instantiateInitialController() as? NSWindowController
        
        controller?.showWindow(sender)
        
    }
    
    // Menu Stuff
    
    @IBAction func openPickerMenu(_ sender: NSMenuItem) {
        popoverViewController.show()
    }
    
    @IBAction func closePickerMenu(_ sender: Any) {
        popoverViewController.hide()
    }
    
    @IBAction func executeLastScript(_ sender: Any) {
        popoverViewController.runScriptAgain()
    }

    @IBAction func undoLastScript(_ sender: Any) {
        scriptManager.undoLastScript(editor: editor)
    }

    @IBAction func redoLastScript(_ sender: Any) {
        scriptManager.redoLastScript(editor: editor)
    }

    @IBAction func clearScriptHistory(_ sender: Any) {
        scriptManager.clearHistory()
    }

    @IBAction func newScript(_ sender: Any) {
        editor.contentTextView.string = ScriptManager.defaultScriptTemplate
        editingScriptURL = nil
    }

    @IBAction func openScript(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["js"]
        if let url = try? ScriptManager.getBookmarkURL() {
            panel.directoryURL = url
        }
        panel.begin { [weak self] result in
            guard let self = self,
                  result == .OK,
                  let url = panel.url else { return }
            self.editingScriptURL = url
            self.editor.contentTextView.string = (try? String(contentsOf: url)) ?? ""
        }
    }

    @IBAction func saveScript(_ sender: Any) {
        if let url = editingScriptURL {
            do {
                try editor.contentTextView.string.write(to: url, atomically: true, encoding: .utf8)
                scriptManager.reloadScripts()
            } catch {
                print("Failed to save script", error)
            }
        } else {
            saveScriptAs(sender)
        }
    }

    @IBAction func saveScriptAs(_ sender: Any) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["js"]
        panel.nameFieldStringValue = editingScriptURL?.lastPathComponent ?? "NewScript.js"
        if let url = try? ScriptManager.getBookmarkURL() {
            panel.directoryURL = url
        }
        panel.begin { [weak self] result in
            guard let self = self,
                  result == .OK,
                  let url = panel.url else { return }
            do {
                try self.editor.contentTextView.string.write(to: url, atomically: true, encoding: .utf8)
                self.editingScriptURL = url
                self.scriptManager.reloadScripts()
            } catch {
                print("Failed to save script", error)
            }
        }
    }

    @IBAction func deleteScript(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["js"]
        if let url = try? ScriptManager.getBookmarkURL() {
            panel.directoryURL = url
        }
        panel.begin { [weak self] result in
            guard let self = self,
                  result == .OK,
                  let url = panel.url else { return }
            let alert = NSAlert()
            alert.messageText = "Delete Script?"
            alert.informativeText = url.lastPathComponent
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            alert.beginSheetModal(for: self.window) { response in
                if response == .alertFirstButtonReturn {
                    do {
                        try FileManager.default.removeItem(at: url)
                        if url == self.editingScriptURL {
                            self.editingScriptURL = nil
                        }
                        self.scriptManager.reloadScripts()
                    } catch {
                        print("Failed to delete script", error)
                    }
                }
            }
        }
    }

    @IBAction func reloadScripts(_ sender: Any) {
        scriptManager.reloadScripts()
    }
    
    func setPopover(isOpen: Bool) {
        closePickerMenuItem.isHidden = !isOpen
        openPickerMenuItem.isHidden = isOpen
    }

    @objc func textServiceHandler(_ pboard: NSPasteboard, userData: String, error: NSErrorPointer) {
        if let string = pboard.string(forType: NSPasteboard.PasteboardType.string) {
            editor.contentTextView.string = string
        }
    }

}

extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.identifier?.rawValue {
        case "UNDO-SCRIPT-ITEM":
            if let name = scriptManager.peekUndoScriptName() {
                menuItem.title = "Undo \(name)"
                return true
            } else {
                menuItem.title = "Undo Last Script"
                return false
            }
        case "REDO-SCRIPT-ITEM":
            if let name = scriptManager.peekRedoScriptName() {
                menuItem.title = "Redo \(name)"
                return true
            } else {
                menuItem.title = "Redo Last Script"
                return false
            }
        case "CLEAR-HISTORY-ITEM":
            return scriptManager.canClearHistory
        case "SAVE-SCRIPT-ITEM":
            return editingScriptURL != nil
        case "DELETE-SCRIPT-ITEM":
            return true
        case "SAVE-AS-SCRIPT-ITEM":
            return true
        default:
            return true
        }
    }
}

