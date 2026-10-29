import Foundation
import ServiceManagement

/// Launch at login: `SMAppService` on macOS 13+, the bundled LoginItems helper (Sources/RemoteFitLoginItem) before it.
enum LoginItem {
    /// Passed by the helper; must match Sources/RemoteFitLoginItem/main.swift.
    static let launchArgument = "--launched-as-login-item"
    private static let helperIdentifier = "local.RemoteFit.LoginItem"
    /// `SMLoginItemSetEnabled` has no getter, so macOS 12 remembers the last successful request.
    private static let legacyEnabledKey = "legacyLoginItemEnabled"

    static var isEnabled: Bool {
        if #available(macOS 13, *) { return SMAppService.mainApp.status == .enabled }
        return UserDefaults.standard.bool(forKey: legacyEnabledKey)
    }

    static func setEnabled(_ enabled: Bool) {
        if #available(macOS 13, *) {
            if enabled, SMAppService.mainApp.status != .enabled { try? SMAppService.mainApp.register() }
            if !enabled, SMAppService.mainApp.status == .enabled { try? SMAppService.mainApp.unregister() }
        } else if SMLoginItemSetEnabled(helperIdentifier as CFString, enabled) {
            UserDefaults.standard.set(enabled, forKey: legacyEnabledKey)
        }
    }
}
