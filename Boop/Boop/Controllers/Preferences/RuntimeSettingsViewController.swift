import Cocoa

class RuntimeSettingsViewController: NSViewController {
    let interpreters: [ScriptInterpreter] = [.python, .ruby, .perl, .lua, .node]

    override func viewDidLoad() {
        super.viewDidLoad()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        ])
        for inter in interpreters {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 10
            let check = NSButton(checkboxWithTitle: inter.displayName, target: self, action: #selector(toggleEnabled(_:)))
            check.identifier = NSUserInterfaceItemIdentifier(inter.enableKey)
            check.state = inter.isEnabled ? .on : .off
            let field = NSTextField(string: UserDefaults.standard.string(forKey: inter.pathKey) ?? inter.command(bundle: Bundle.main)?[0] ?? "")
            field.identifier = NSUserInterfaceItemIdentifier(inter.pathKey)
            field.target = self
            field.action = #selector(pathChanged(_:))
            let keywordField = NSTextField(string: inter.requireKeyword)
            keywordField.identifier = NSUserInterfaceItemIdentifier(inter.requireKey)
            keywordField.target = self
            keywordField.action = #selector(runtimeKeywordChanged(_:))
            row.addArrangedSubview(check)
            row.addArrangedSubview(field)
            row.addArrangedSubview(keywordField)
            stack.addArrangedSubview(row)
        }

        let reqRow = NSStackView()
        reqRow.orientation = .horizontal
        reqRow.spacing = 10
        let label = NSTextField(labelWithString: "Default keyword")
        let reqField = NSTextField(string: UserDefaults.standard.string(forKey: "runtime.require.keyword") ?? "")
        reqField.identifier = NSUserInterfaceItemIdentifier("runtime.require.keyword")
        reqField.target = self
        reqField.action = #selector(defaultKeywordChanged(_:))
        reqRow.addArrangedSubview(label)
        reqRow.addArrangedSubview(reqField)
        stack.addArrangedSubview(reqRow)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        preferredContentSize = view.fittingSize
    }

    @objc func toggleEnabled(_ sender: NSButton) {
        guard let key = sender.identifier?.rawValue else { return }
        UserDefaults.standard.set(sender.state == .on, forKey: key)
    }

    @objc func pathChanged(_ sender: NSTextField) {
        guard let key = sender.identifier?.rawValue else { return }
        UserDefaults.standard.set(sender.stringValue, forKey: key)
    }

    @objc func runtimeKeywordChanged(_ sender: NSTextField) {
        guard let key = sender.identifier?.rawValue else { return }
        UserDefaults.standard.set(sender.stringValue, forKey: key)
    }

    @objc func defaultKeywordChanged(_ sender: NSTextField) {
        UserDefaults.standard.set(sender.stringValue, forKey: "runtime.require.keyword")
    }
}
