//
//  ScriptManager.swift
//  Yup
//
//  Created by Ivan on 1/15/17.
//  Copyright © 2017 OKatBest. All rights reserved.
//

import Cocoa
import SavannaKit
import Fuse


class ScriptManager: NSObject {
    
    
    
    static let userPreferencesPathKey = "scriptsFolderPath"
    static let userPreferencesDataKey = "scriptsFolderData"
    static let defaultScriptTemplate = """
/**
  {
    \"api\":1,
    \"name\":\"New Boop Script\",
    \"description\":\"What does your script do?\",
    \"author\":\"\",
    \"icon\":\"broom\",
    \"tags\":\"example\"
  }
**/

function main(state) {
  try {
    // Your code here
  } catch (error) {
    state.postError(String(error))
  }
}
"""
    
    // This probably does not belong here.
    @IBOutlet weak var statusView: StatusView!
    
    let fuse = Fuse(threshold: 0.2)
    var scripts = [Script]()
    
    let currentAPIVersion = 1.0
    
    var lastScript: Script?

    static let userPreferencesHistoryDepthKey = "scriptHistoryDepth"

    private struct EditorState {
        let text: String
        let ranges: [NSRange]
        let scriptName: String?
    }

    private var undoStack: [EditorState] = []
    private var redoStack: [EditorState] = []

    private var maxHistoryDepth: Int {
        let stored = UserDefaults.standard.integer(forKey: ScriptManager.userPreferencesHistoryDepthKey)
        return stored > 0 ? stored : 20
    }
    
    override init() {
        super.init()

        loadDefaultScripts()
        loadUserScripts()
    }

    private func captureState(editor: SyntaxTextView, scriptName: String?) {
        let text = editor.text
        let ranges = (editor.contentTextView.selectedRanges as? [NSRange]) ?? []
        undoStack.append(EditorState(text: text, ranges: ranges, scriptName: scriptName))
        if undoStack.count > maxHistoryDepth {
            undoStack.removeFirst(undoStack.count - maxHistoryDepth)
        }
        redoStack.removeAll()
    }

    func undoLastScript(editor: SyntaxTextView) {
        guard let last = undoStack.popLast() else {
            NSSound.beep()
            return
        }

        let current = EditorState(text: editor.text,
                                  ranges: (editor.contentTextView.selectedRanges as? [NSRange]) ?? [],
                                  scriptName: last.scriptName)
        redoStack.append(current)
        replaceText(ranges: [NSRange(location: 0, length: editor.contentTextView.textStorage?.length ?? editor.text.count)], values: [last.text], editor: editor)
        editor.contentTextView.selectedRanges = last.ranges.map { NSValue(range: $0) }
    }

    func redoLastScript(editor: SyntaxTextView) {
        guard let next = redoStack.popLast() else {
            NSSound.beep()
            return
        }

        let current = EditorState(text: editor.text,
                                  ranges: (editor.contentTextView.selectedRanges as? [NSRange]) ?? [],
                                  scriptName: next.scriptName)
        undoStack.append(current)
        replaceText(ranges: [NSRange(location: 0, length: editor.contentTextView.textStorage?.length ?? editor.text.count)], values: [next.text], editor: editor)
        editor.contentTextView.selectedRanges = next.ranges.map { NSValue(range: $0) }
    }
    

    static func setBookmarkData(url: URL) throws {
        
        let data = try url.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        
        UserDefaults.standard.set(data, forKey: ScriptManager.userPreferencesDataKey)
    }
    
    /// Load built in scripts
    func loadDefaultScripts(){
        ScriptInterpreter.supportedExtensions.forEach { ext in
            let interpreter = ScriptInterpreter(fileExtension: ext)
            guard interpreter.isEnabled else { return }
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "scripts")

            urls?.forEach { script in
                loadScript(url: script, builtIn: true)
            }
        }
    }
    
    
    /// Load user scripts
    func loadUserScripts(){
        
        do {
            
            guard let url = try ScriptManager.getBookmarkURL() else {
                return
            }
            
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            urls.forEach { url in
                let ext = url.pathExtension
                guard ScriptInterpreter.isSupported(ext) else { return }
                let interpreter = ScriptInterpreter(fileExtension: ext)
                guard interpreter.isEnabled else { return }
                loadScript(url: url, builtIn: false)
            }
            
        }
        catch let error {
            print(error)
            return
        }
    }
    
    /// Parses a script file
    private func loadScript(url: URL, builtIn: Bool){
        do{
            let script = try String(contentsOf: url)
            
            // This is inspired by the ISF file format by Vidvox
            // Thanks to them for the idea and their awesome work
            
            guard
                let openComment = script.range(of: "/**"),
                let closeComment = script.range(of: "**/")
                else {
                    throw NSError()
            }
            
            let meta = script[openComment.upperBound..<closeComment.lowerBound]
            
            let json = try JSONSerialization.jsonObject(with: meta.data(using: .utf8)!, options: .allowFragments) as! [String: Any]
            
            let interpreter = ScriptInterpreter(fileExtension: url.pathExtension)
            guard interpreter.isEnabled else { return }
            let scriptObject = Script(url: url, script: script, parameters: json, builtIn: builtIn, interpreter: interpreter, delegate: self)

            scripts.append(scriptObject)
            
            
        } catch {
            print("Unable to load ", url)
        }
    }
    
    func search(_ query: String) -> [Script] {

        guard query.count < 20 else {
            // If the query is too long let's just ignore it.
            // It's probably the user pasting the wrong thing
            // in the search box by accident which overwhelms
            // fuse and crashes the app. Whoops!
            return []
        }

        var searchQuery = query
        var filterCategories: [String] = []

        let regex = try? NSRegularExpression(pattern: "(?i)\\b(?:cat|category):([\\w,-]+)")
        if let match = regex?.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)),
           let range = Range(match.range(at: 1), in: query) {
            filterCategories = query[range]
                .split { $0 == "," || $0.isWhitespace }
                .map { $0.lowercased() }
            searchQuery = regex!.stringByReplacingMatches(in: query, range: NSRange(query.startIndex..., in: query), withTemplate: "")
            searchQuery = searchQuery.trimmingCharacters(in: .whitespaces)
        }

        if searchQuery == "*" || searchQuery.isEmpty {
            var all = scripts.sorted { left, right in
                left.name ?? "" < right.name ?? ""
            }
            if !filterCategories.isEmpty {
                all = all.filter { script in
                    guard let cats = script.categories else { return false }
                    return filterCategories.allSatisfy { cats.contains($0) }
                }
            }
            return all
        }

        let results = fuse.search(searchQuery, in: scripts)

        var filtered = results.filter { result in
            result.score < 0.4 // Filter low quality results
        }.sorted { left, right in
            let leftScore = left.score - (scripts[left.index].bias ?? 0)
            let rightScore = right.score - (scripts[right.index].bias ?? 0)
            return leftScore < rightScore
        }.map { result in
            scripts[result.index]
        }

        if !filterCategories.isEmpty {
            filtered = filtered.filter { script in
                guard let cats = script.categories else { return false }
                return filterCategories.allSatisfy { cats.contains($0) }
            }
        }

        return filtered
    }
    
    func runScript(_ script: Script, into editor: SyntaxTextView) {

        let fullText = editor.text

        lastScript = script
        captureState(editor: editor, scriptName: script.name)

        guard let ranges = editor.contentTextView.selectedRanges as? [NSRange], ranges.reduce(0, { $0 + $1.length }) > 0 else {
            
            let insertPosition = (editor.contentTextView.selectedRanges.first as? NSRange)?.location
            let result = runScript(script, fullText: fullText, insertIndex: insertPosition)
            // No selection, run on full text
            
            let unicodeSafeFullTextLength = editor.contentTextView.textStorage?.length ?? fullText.count
            replaceText(ranges: [NSRange(location: 0, length: unicodeSafeFullTextLength)], values: [result], editor: editor)
            
            return
        }
        
        // Fun fact: You can have multi selections! Which means we need to disable
        // the ability to edit `fullText` while in selection mode, otherwise the
        // some scripts may accidentally run multiple time over the full text.
        
        let values = ranges.map {
            range -> String in
            
            let value = (fullText as NSString).substring(with: range)
            
            return runScript(script, selection: value, fullText: fullText)
            
        }
        
        replaceText(ranges: ranges, values: values, editor: editor)
        
        
    }
    
    private func replaceText(ranges: [NSRange], values: [String], editor: SyntaxTextView) {
        
        
        let textView = editor.contentTextView
        
        // Since we have to replace each selection one by one, after each
        // occurence the whole text shifts around a bit, and therefore the
        // Ranges don't match their original position anymore. So we have
        // to offset everything based on the previous replacements deltas.
        // This is pretty straightforward because we know selections can't
        // overlap, and we sort them so they are always in order.
        
        var offset = 0
        let pairs = zip(ranges, values)
            .sorted{ $0.0.location < $1.0.location }
            .map { (pair) -> (NSRange, String) in
                
                let (range, value) = pair
                let length = range.length
                let newRange = NSRange(location: range.location + offset, length: length)
                
                offset += value.count - length
                return (newRange, value)
        }
        
        
        guard textView.shouldChangeText(inRanges: ranges as [NSValue], replacementStrings: values) else {
            return
        }
        
        textView.textStorage?.beginEditing()
        
        pairs.forEach {
            (range, value) in
            textView.textStorage?.replaceCharacters(in: range, with: value)
        }
        
        
        textView.textStorage?.endEditing()
        
        textView.didChangeText()
    }
    
    func runScript(_ script: Script, selection: String? = nil, fullText: String, insertIndex: Int? = nil) -> String {
        let scriptExecution = ScriptExecution(selection: selection, fullText: fullText, script: script, insertIndex: insertIndex)
        
        self.statusView.setStatus(.normal)
        script.run(with: scriptExecution)
        
        return scriptExecution.text ?? ""
    }
    
    func runScriptAgain(editor: SyntaxTextView) {
        guard let script = lastScript else {
            NSSound.beep()
            return
        }

        runScript(script, into: editor)
    }

    func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    func peekUndoScriptName() -> String? {
        undoStack.last?.scriptName
    }

    func peekRedoScriptName() -> String? {
        redoStack.last?.scriptName
    }

    var canClearHistory: Bool {
        return !undoStack.isEmpty || !redoStack.isEmpty
    }
    
    func reloadScripts() {
        lastScript = nil
        scripts.removeAll()
        loadDefaultScripts()
        loadUserScripts()
        
        statusView.setStatus(.success("Reloaded Scripts"))
    }
    
    static func getBookmarkURL() throws -> URL? {
        
        guard let data = UserDefaults.standard.data(forKey: ScriptManager.userPreferencesDataKey) else {
            // No user path specified, abbandon ship!
            return nil
        }
        
        var isBookmarkStale = false
                  
        let url = try URL.init(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isBookmarkStale)

        if(isBookmarkStale) {
            try ScriptManager.setBookmarkData(url: url)
        }

        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        
        return url
    }
    
}

extension ScriptManager: ScriptDelegate {
    func onScriptError(message: String) {
        self.statusView.setStatus(.error(message))
    }
    
    func onScriptInfo(message: String) {
        self.statusView.setStatus(.info(message))
    }
    
    
}
