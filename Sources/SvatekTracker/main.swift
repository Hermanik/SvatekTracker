import AppKit

// Top-level code runs on the main thread; `assumeIsolated` tells the compiler.
MainActor.assumeIsolated {
    // Dev aid: render the popover to PNGs and exit. See Snapshot.swift.
    if let directory = ProcessInfo.processInfo.environment["SVATEKTRACKER_SNAPSHOT"] {
        Snapshot.run(into: directory)
        exit(0)
    }

    // Menubar-only app: `.accessory` keeps it out of the Dock and the app
    // switcher without needing a bundled Info.plist (LSUIElement is set for the
    // packaged .app in scripts/bundle.sh; this covers `swift run`).
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
