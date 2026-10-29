import AppKit
import Combine
import SvatekTrackerCore
import SwiftUI

/// Borderless panel that can become key (so the search field takes typing)
/// while leaving the app in the background. Escape closes it.
final class PopoverPanel: NSPanel {
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) { onCancel?() }
}

/// Owns the status-bar item and the dropdown panel. A manually positioned panel
/// (instead of NSPopover) gives exact placement under the item — NSPopover
/// mis-positions when the main display isn't at the global coordinate origin.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: PopoverPanel!
    private var dismissMonitor: Any?
    private let model = AppModel()
    private let updater = Updater()
    private var subscriptions = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePanel()
        model.$today.combineLatest(model.$trackedNames)
            .sink { [weak self] today, tracked in self?.updateStatusItem(today: today, tracked: tracked) }
            .store(in: &subscriptions)
        Log.app.info("launched")
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageLeading
        button.action = #selector(statusItemClicked)
        button.target = self
        // Left-click opens the panel; right-click (or control-click) opens a menu.
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    /// Today's names (or holiday) as the title; a star when a tracked name
    /// celebrates today, otherwise a flag on public holidays.
    private func updateStatusItem(today: Day, tracked: [String]) {
        guard let button = statusItem.button else { return }
        let info = DayInfo(today)
        button.title = info.title
        let symbol: String? =
            if !info.celebrated(by: tracked).isEmpty {
                "star.fill"
            } else if info.holiday != nil {
                "flag.fill"
            } else {
                nil
            }
        button.image = symbol.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: nil) }
        let tomorrow = DayInfo(today.adding(days: 1)).title
        button.toolTip = "Dnes: \(info.title)\(info.holiday.map { " (\($0.name))" } ?? "")\nZítra: \(tomorrow)"
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func showMenu() {
        guard let button = statusItem.button else { return }
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(withTitle: "O aplikaci SvátekTracker", action: #selector(showAbout), keyEquivalent: "")
        let updates = NSMenuItem(
            title: "Zkontrolovat aktualizace…", action: #selector(checkForUpdates), keyEquivalent: "")
        updates.isEnabled = updater.isAvailable
        menu.addItem(updates)
        let login = NSMenuItem(title: "Spouštět po přihlášení", action: #selector(toggleLoginItem), keyEquivalent: "")
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Ukončit SvátekTracker", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    @objc private func checkForUpdates() { updater.checkForUpdates() }

    @objc private func toggleLoginItem() { LoginItem.setEnabled(!LoginItem.isEnabled) }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() { NSApplication.shared.terminate(nil) }

    private func configurePanel() {
        panel = PopoverPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 520),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.onCancel = { [weak self] in self?.hide() }
        panel.contentView = NSHostingView(rootView: PopoverView(model: model))
    }

    private func show() {
        guard let button = statusItem.button, let buttonWindow = button.window,
            let content = panel.contentView
        else { return }
        model.refresh()
        content.layoutSubtreeIfNeeded()
        let size = content.fittingSize
        panel.setContentSize(size)
        // Centered under the item, but kept on screen when the item sits near
        // the right edge.
        var x = buttonWindow.frame.midX - size.width / 2
        if let screen = buttonWindow.screen?.visibleFrame {
            x = min(max(x, screen.minX + 8), screen.maxX - size.width - 8)
        }
        panel.setFrameOrigin(NSPoint(x: x, y: buttonWindow.frame.minY - size.height - 6))
        panel.makeKeyAndOrderFront(nil)
        // Close when the user clicks outside the panel (events in other apps /
        // the menu bar); clicks on our own status item stay local and toggle.
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            self?.hide()
        }
    }

    private func hide() {
        panel.orderOut(nil)
        if let monitor = dismissMonitor {
            NSEvent.removeMonitor(monitor)
            dismissMonitor = nil
        }
    }
}
