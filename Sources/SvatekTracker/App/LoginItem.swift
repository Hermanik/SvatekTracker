import Foundation
import ServiceManagement

/// Launch-at-login backed by `SMAppService` (macOS 13+). Registration persists
/// across launches in the system's login-items database, so there's nothing to
/// store ourselves. Only works from a real bundle, not `swift run`.
enum LoginItem {
    /// `.enabled` when on; `.requiresApproval` when registered but switched off
    /// in System Settings > Login Items.
    static var status: SMAppService.Status { SMAppService.mainApp.status }

    static func openSystemSettings() { SMAppService.openSystemSettingsLoginItems() }

    /// A menu bar calendar is only useful while it runs, so the first launch
    /// from /Applications turns launch at login on — once; after that it's the
    /// user's call in Settings. Elsewhere (a mounted DMG, a translocated
    /// download, `swift run`) the path isn't stable enough to register.
    static func enableOnFirstLaunch() {
        guard !UserDefaults.standard.bool(forKey: defaultedKey),
            Bundle.main.bundlePath.hasPrefix("/Applications/")
        else { return }
        UserDefaults.standard.set(true, forKey: defaultedKey)
        setEnabled(true)
    }

    private static let defaultedKey = "loginItemDefaulted"

    /// Register or unregister the app as a login item; logs and swallows the
    /// rare failure (e.g. the user disabled it in System Settings) rather than
    /// surfacing it from a menu click.
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Log.app.error(
                "Login item \(enabled ? "register" : "unregister", privacy: .public) failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
