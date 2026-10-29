import AppKit
import SwiftUI

/// Dev aid: `SVATEKTRACKER_SNAPSHOT=<dir> swift run` renders the popover once
/// per tab into `<dir>/<tab>.png`, plus the settings window into
/// `<dir>/settings.png`, and exits — a visual check that needs neither a click
/// on the menu bar nor the Screen Recording permission.
@MainActor
enum Snapshot {
    static func run(into directory: String) {
        let model = AppModel()
        for tab in PopoverView.Tab.allCases {
            render(PopoverView(model: model, tab: tab), as: "\(tab)", into: directory)
        }
        render(SettingsView(model: model, updater: Updater()), as: "settings", into: directory)
    }

    private static func render(_ root: some View, as name: String, into directory: String) {
        let view = NSHostingView(rootView: root)
        view.frame.size = view.fittingSize
        // An offscreen window gives SwiftUI a backing to draw the material
        // and AppKit-hosted controls into.
        let window = NSWindow(contentRect: view.bounds, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = .windowBackgroundColor
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).png")
        do {
            try trimmed(rep).representation(using: .png, properties: [:])?.write(to: url)
            print("wrote \(url.path)")
        } catch {
            print("failed to write \(url.path): \(error.localizedDescription)")
        }
    }

    /// Drops the fully transparent rows above and below the content (the
    /// grouped Form's insets), so the PNG goes into docs/ as is.
    private static func trimmed(_ rep: NSBitmapImageRep) -> NSBitmapImageRep {
        let x = rep.pixelsWide / 2
        let opaque = (0..<rep.pixelsHigh).filter { (rep.colorAt(x: x, y: $0)?.alphaComponent ?? 0) > 0 }
        guard let top = opaque.first, let bottom = opaque.last,
            let image = rep.cgImage?.cropping(
                to: CGRect(x: 0, y: top, width: rep.pixelsWide, height: bottom - top + 1))
        else { return rep }
        return NSBitmapImageRep(cgImage: image)
    }
}
