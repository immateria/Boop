//
//  Script.swift
//  Boop
//
//  Created by Ivan on 2/13/19.
//  Copyright © 2019 OKatBest. All rights reserved.
//

import Foundation
import JavaScriptCore
import Fuse

enum ScriptPermission: String {
    case network
    case llm
}

enum ScriptInterpreter {
    case javaScriptCore
    case python
    case ruby
    case perl
    case lua
    case node

    init(fileExtension ext: String) {
        switch ext.lowercased() {
        case "py": self = .python
        case "rb": self = .ruby
        case "pl": self = .perl
        case "lua": self = .lua
        case "njs": self = .node
        default: self = .javaScriptCore
        }
    }

    func command(bundle: Bundle) -> [String]? {
        guard isEnabled else { return nil }
        switch self {
        case .javaScriptCore:
            return nil
        case .python:
            guard let bridge = bundle.path(forResource: "bridge", ofType: "py", inDirectory: "bridges/python") else { return nil }
            let path = UserDefaults.standard.string(forKey: pathKey) ?? "python3"
            return [path, bridge]
        case .ruby:
            guard let bridge = bundle.path(forResource: "bridge", ofType: "rb", inDirectory: "bridges/ruby") else { return nil }
            let path = UserDefaults.standard.string(forKey: pathKey) ?? "ruby"
            return [path, bridge]
        case .perl:
            guard let bridge = bundle.path(forResource: "bridge", ofType: "pl", inDirectory: "bridges/perl") else { return nil }
            let path = UserDefaults.standard.string(forKey: pathKey) ?? "perl"
            return [path, bridge]
        case .lua:
            guard let bridge = bundle.path(forResource: "bridge", ofType: "lua", inDirectory: "bridges/lua") else { return nil }
            let path = UserDefaults.standard.string(forKey: pathKey) ?? "lua"
            return [path, bridge]
        case .node:
            guard let bridge = bundle.path(forResource: "bridge", ofType: "js", inDirectory: "bridges/node") else { return nil }
            let path = UserDefaults.standard.string(forKey: pathKey) ?? "node"
            return [path, bridge]
        }
    }

    static var supportedExtensions: [String] {
        return ["js", "py", "rb", "pl", "lua", "njs"]
    }

    var enableKey: String {
        switch self {
        case .javaScriptCore: return "runtime.js.enabled"
        case .python: return "runtime.py.enabled"
        case .ruby: return "runtime.rb.enabled"
        case .perl: return "runtime.pl.enabled"
        case .lua: return "runtime.lua.enabled"
        case .node: return "runtime.node.enabled"
        }
    }

    var pathKey: String {
        switch self {
        case .javaScriptCore: return "runtime.js.path"
        case .python: return "runtime.py.path"
        case .ruby: return "runtime.rb.path"
        case .perl: return "runtime.pl.path"
        case .lua: return "runtime.lua.path"
        case .node: return "runtime.node.path"
        }
    }

    var displayName: String {
        switch self {
        case .javaScriptCore: return "JavaScript"
        case .python: return "Python"
        case .ruby: return "Ruby"
        case .perl: return "Perl"
        case .lua: return "Lua"
        case .node: return "Node.js"
        }
    }

    var shortName: String {
        switch self {
        case .javaScriptCore: return "JS"
        case .python: return "PY"
        case .ruby: return "RB"
        case .perl: return "PL"
        case .lua: return "LUA"
        case .node: return "NODE"
        }
    }

    var isEnabled: Bool {
        if self == .javaScriptCore { return true }
        return UserDefaults.standard.object(forKey: enableKey) as? Bool ?? true
    }

    var moduleExtension: String {
        switch self {
        case .javaScriptCore: return ".js"
        case .python: return ".py"
        case .ruby: return ".rb"
        case .perl: return ".pl"
        case .lua: return ".lua"
        case .node: return ".njs"
        }
    }

    var defaultRequireKeyword: String {
        switch self {
        case .javaScriptCore, .node:
            return "require"
        default:
            return "boop_require"
        }
    }

    static var globalRequireKeyword: String? {
        UserDefaults.standard.string(forKey: "runtime.require.keyword")
    }

    var requireKey: String {
        switch self {
        case .javaScriptCore: return "runtime.js.require.keyword"
        case .python: return "runtime.py.require.keyword"
        case .ruby: return "runtime.rb.require.keyword"
        case .perl: return "runtime.pl.require.keyword"
        case .lua: return "runtime.lua.require.keyword"
        case .node: return "runtime.node.require.keyword"
        }
    }

    var requireKeyword: String {
        if let per = UserDefaults.standard.string(forKey: requireKey) {
            return per
        }
        if let global = ScriptInterpreter.globalRequireKeyword {
            return global
        }
        return defaultRequireKeyword
    }

    static func isSupported(_ ext: String) -> Bool {
        supportedExtensions.contains(ext.lowercased())
    }
}

class Script: NSObject {

    var isBuiltInt: Bool
    var url: URL
    var scriptCode: String
    var interpreter: ScriptInterpreter
    var permissions: Set<ScriptPermission>
    
    
    lazy var context: JSContext? = { [unowned self] in
        guard interpreter == .javaScriptCore else { return nil }
        let context: JSContext = JSContext()
        context.name = self.name ?? "Unknown Script"

        context.exceptionHandler = { [unowned self] context, exception in
            let message = "[\(self.name ?? "Unknown Script")] Error: \(exception?.toString() ?? "Unknown Error") "
            print(message)
            self.onScriptError(message: message)
        }

        self.setupRequire(context: context)

        context.setObject(ScriptExecution.self, forKeyedSubscript: "ScriptExecution" as NSString)

        context.evaluateScript(self.scriptCode, withSourceURL: url)

        return context
    }()

    lazy var main: JSValue? = {
        context?.objectForKeyedSubscript("main")
    }()
    
    var info:[String: Any]
    
    var name: String?
    var tags: String?
    var desc: String?
    var icon: String?
    var bias: Double?
    var categories: [String]?
    
    weak var delegate: ScriptDelegate?
    
    init(url: URL, script:String, parameters: [String: Any], builtIn: Bool, interpreter: ScriptInterpreter, delegate: ScriptDelegate? = nil) {
        
        
        self.scriptCode = script
        self.info = parameters
        self.url = url
        self.isBuiltInt = builtIn
        self.interpreter = interpreter
        if let perms = parameters["permissions"] as? [String] {
            self.permissions = Set(perms.compactMap { ScriptPermission(rawValue: $0.lowercased()) })
        } else if let perm = parameters["permissions"] as? String {
            let split = perm.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            self.permissions = Set(split.compactMap { ScriptPermission(rawValue: $0) })
        } else {
            self.permissions = []
        }
        
        self.name = parameters["name"] as? String
        self.tags = parameters["tags"] as? String
        self.desc = parameters["description"] as? String
        self.icon = (parameters["icon"] as? String)?.lowercased()
        self.bias = parameters["bias"] as? Double

        if let cats = parameters["categories"] as? [String] {
            let lower = cats.map { $0.lowercased() }
            self.categories = Array(Set(lower)).sorted()
        } else if let cats = parameters["categories"] as? String {
            let lower = cats
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            self.categories = Array(Set(lower)).sorted()
        }
        
        
        
        // We set the delegate after the initial eval to avoid
        // showing init errors from scripts at launch.
        self.delegate = delegate
        
    }
    
    func onScriptError(message: String) {
        self.delegate?.onScriptError(message: message)
    }
    
    func onScriptInfo(message: String) {
        self.delegate?.onScriptInfo(message: message)
    }

    func run(with execution: ScriptExecution) {
        switch interpreter {
        case .javaScriptCore:
            main?.call(withArguments: [execution])
        case .python, .ruby, .perl, .lua, .node:
            runExternal(with: execution)
        }
    }

    private func runExternal(with execution: ScriptExecution) {
        guard let command = interpreter.command(bundle: Bundle.main) else { return }

        var env = ProcessInfo.processInfo.environment
        var state: [String: Any] = [
            "text": execution.text ?? "",
            "fullText": execution.fullText ?? "",
            "selection": execution.selection ?? "",
            "network": permissions.contains(.network)
        ]
        if let data = try? JSONSerialization.data(withJSONObject: state, options: []) {
            env["BOOP_STATE"] = String(data: data, encoding: .utf8)
        }

        env["BOOP_MODULE_EXT"] = interpreter.moduleExtension
        env["BOOP_SCRIPT_DIR"] = url.deletingLastPathComponent().path
        if let lib = Bundle.main.resourceURL?.appendingPathComponent("scripts/lib").path {
            env["BOOP_LIB_DIR"] = lib
        }
        env["BOOP_REQUIRE_NAME"] = interpreter.requireKeyword

        let process = Process()
        process.launchPath = command.first
        process.arguments = Array(command.dropFirst()) + [url.path]
        process.environment = env

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        process.launch()
        process.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        outputPipe.fileHandleForReading.closeFile()

        guard
            let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else { return }

        if let text = dict["text"] as? String { execution.text = text }
        if let full = dict["fullText"] as? String { execution.fullText = full }
        if let sel = dict["selection"] as? String { execution.selection = sel }
        if let inserts = dict["inserts"] as? [String] {
            inserts.forEach { execution.insert($0) }
        }
        if let messages = dict["messages"] as? [[String: String]] {
            for msg in messages {
                if msg["type"] == "error", let m = msg["message"] {
                    execution.postError(m)
                } else if msg["type"] == "info", let m = msg["message"] {
                    execution.postInfo(m)
                }
            }
        }
    }
    
}

extension Script: Fuseable {
    
    var properties: [FuseProperty] {
        return [
            FuseProperty(value: name, weight: 0.9),
            FuseProperty(value: tags, weight: 0.6),
            FuseProperty(value: categories?.joined(separator: " "), weight: 0.4),
            FuseProperty(value: desc, weight: 0.2)
        ]
    }
}

protocol ScriptDelegate: class {
    func onScriptError(message: String)
    func onScriptInfo(message: String)
}
