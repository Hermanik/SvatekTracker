import ServiceManagement

/// Launch-at-login backed by `SMAppService` (macOS 13+). Registration persists
/// across launches in the system's login-items database, so there's nothing to
/// store ourselves. Only works from a real bundle, not `swift run`.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

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
