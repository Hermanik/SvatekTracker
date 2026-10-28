import AppKit
import SwiftUI

/// Dev aid: `SVATEKTRACKER_SNAPSHOT=<dir> swift run` renders the popover once
/// per tab into `<dir>/<tab>.png` and exits — a visual check that needs neither
/// a click on the menu bar nor the Screen Recording permission.
@MainActor
enum Snapshot {
    static func run(into directory: String) {
        let model = AppModel()
        for tab in PopoverView.Tab.allCases {
            let view = NSHostingView(rootView: PopoverView(model: model, tab: tab))
            view.frame.size = view.fittingSize
            // An offscreen window gives SwiftUI a backing to draw the material
            // and AppKit-hosted controls into.
            let window = NSWindow(
                contentRect: view.bounds, styleMask: .borderless, backing: .buffered, defer: false)
            window.backgroundColor = .windowBackgroundColor
            window.contentView = view
            view.layoutSubtreeIfNeeded()
            guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
            view.cacheDisplay(in: view.bounds, to: rep)
            let url = URL(fileURLWithPath: directory).appendingPathComponent("\(tab).png")
            do {
                try rep.representation(using: .png, properties: [:])?.write(to: url)
                print("wrote \(url.path)")
            } catch {
                print("failed to write \(url.path): \(error.localizedDescription)")
            }
        }
    }
}
