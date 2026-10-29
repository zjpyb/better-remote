import AppKit

// macOS 12 login item: Better Remote.app/Contents/Library/LoginItems/<this>.app opens the enclosing app, then quits.
let app = Bundle.main.bundleURL
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let configuration = NSWorkspace.OpenConfiguration()
configuration.arguments = ["--launched-as-login-item"]
NSWorkspace.shared.openApplication(at: app, configuration: configuration) { _, _ in exit(0) }
RunLoop.main.run()
