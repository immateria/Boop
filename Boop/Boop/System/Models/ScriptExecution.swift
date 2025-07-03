//
//  ScriptExecution.swift
//  Boop
//
//  Created by Ivan on 4/21/19.
//  Copyright © 2019 OKatBest. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol ScriptExecutionJSExport: JSExport {
    var selection: String? { get set }
    var fullText: String? { get set }
    var text: String? { get set }
    var isSelection: Bool { get }
    func postError(_ error: String)
    func postInfo(_ info: String)
    func insert(_ newValue: String)
    func fetch(_ url: String, _ method: String?, _ body: String?) -> String?
}


@objc class ScriptExecution: NSObject, ScriptExecutionJSExport {
    
    var isSelection: Bool
    var selection: String?
    var fullText: String?
    let insertIndex: Int?
    
    var insertOffset: Int = 0
    
    private weak var script: Script?
    
    init(selection: String?, fullText: String, script: Script, insertIndex: Int?) {
        self.isSelection = (selection != nil)
        self.selection = selection
        self.fullText = fullText
        self.script = script
        self.insertIndex = insertIndex
    }
    
    var text: String? {
        get {
            return isSelection ? selection : fullText
        }
        set{
            if isSelection {
                selection = newValue
            } else {
                fullText = newValue
            }
        }
    }
    
    
    func postError(_ error: String) {
        self.script?.onScriptError(message: error)
    }
    func postInfo(_ info: String) {
        self.script?.onScriptInfo(message: info)
    }
    
    func insert(_ newValue: String) {
        guard !isSelection else {
            selection = newValue
            return
        }
        guard
            let insertIndex = self.insertIndex, fullText != nil,
            let fullText = fullText,
            let range = Range(NSMakeRange(insertIndex, 0), in: fullText)
         else {
            self.fullText = newValue
            return
        }
        
        let point = fullText.index(range.lowerBound, offsetBy: self.insertOffset)

        self.fullText?.insert(contentsOf: newValue, at: point)
        
        self.insertOffset += newValue.count

    }

    func fetch(_ url: String, _ method: String? = nil, _ body: String? = nil) -> String? {
        guard script?.permissions.contains(.network) == true else {
            postError("Network permission required")
            return nil
        }
        guard let u = URL(string: url) else { return nil }
        var request = URLRequest(url: u)
        request.httpMethod = method ?? "GET"
        if let body = body { request.httpBody = body.data(using: .utf8) }
        let sema = DispatchSemaphore(value: 0)
        var result: String?
        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                result = String(data: data, encoding: .utf8)
            } else {
                self.postError("Failed to fetch")
            }
            sema.signal()
        }
        task.resume()
        sema.wait()
        return result
    }
}
