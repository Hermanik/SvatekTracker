import AppKit
import Foundation

/// Wires Sparkle for in-app updates without linking it at build time: the
/// framework is embedded in the bundle (bundle.sh) and loaded at runtime, so a
/// plain `swift build` / CI never needs Sparkle.
///
/// Only a little is needed — start background checks at launch (which also
/// powers the appcast-based analytics), a manual "Check for Updates…", and the
/// on/off switch for the background checks — so the runtime surface stays
/// tiny. When Sparkle isn't present (e.g. `swift run` during development) this
/// degrades to a no-op.
final class Updater: ObservableObject {
    /// `SPUStandardUpdaterController`, retained for the app's lifetime; nil when
    /// Sparkle didn't load.
    private let controller: AnyObject?
    /// The controller's `SPUUpdater`, reached through KVC like the rest of Sparkle.
    private let sparkleUpdater: NSObject?

    /// Whether Sparkle loaded and the updater is live.
    var isAvailable: Bool { controller != nil }

    init() {
        controller = Self.makeController()
        sparkleUpdater = (controller as? NSObject)?.value(forKey: "updater") as? NSObject
        if controller == nil {
            Log.updater.notice("Sparkle unavailable — updates off (expected under `swift run`)")
        } else {
            Log.updater.info("Sparkle updater started")
        }
    }

    /// Sparkle's daily background check. Sparkle persists the choice in the
    /// app's user defaults itself, so there's no setting of our own to keep.
    var automaticallyChecks: Bool {
        get { sparkleUpdater?.value(forKey: "automaticallyChecksForUpdates") as? Bool ?? false }
        set {
            objectWillChange.send()
            sparkleUpdater?.setValue(newValue, forKey: "automaticallyChecksForUpdates")
        }
    }

    /// Trigger a user-initiated update check (Sparkle shows its standard UI).
    func checkForUpdates() {
        guard let controller, let msgSend = Self.objcMsgSend else { return }
        let send = unsafeBitCast(msgSend, to: (@convention(c) (AnyObject, Selector, AnyObject?) -> Void).self)
        send(controller, NSSelectorFromString("checkForUpdates:"), nil)
    }

    // MARK: - Runtime loading

    private static let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
    private static var objcMsgSend: UnsafeMutableRawPointer? { dlsym(rtldDefault, "objc_msgSend") }

    private static func makeController() -> AnyObject? {
        guard let frameworks = Bundle.main.privateFrameworksPath,
            dlopen(frameworks + "/Sparkle.framework/Sparkle", RTLD_NOW) != nil,
            let cls: AnyClass = NSClassFromString("SPUStandardUpdaterController"),
            let msgSend = objcMsgSend
        else { return nil }

        typealias AllocFn = @convention(c) (AnyClass, Selector) -> Unmanaged<AnyObject>
        typealias InitFn =
            @convention(c) (AnyObject, Selector, ObjCBool, AnyObject?, AnyObject?) -> Unmanaged<AnyObject>
        let alloc = unsafeBitCast(msgSend, to: AllocFn.self)
        let initialize = unsafeBitCast(msgSend, to: InitFn.self)

        // [[SPUStandardUpdaterController alloc] initWithStartingUpdater:YES
        //   updaterDelegate:nil userDriverDelegate:nil]. alloc's +1 is consumed
        // by init, whose +1 we take ownership of for the app's lifetime.
        let allocated = alloc(cls, NSSelectorFromString("alloc")).takeUnretainedValue()
        let controller = initialize(
            allocated,
            NSSelectorFromString("initWithStartingUpdater:updaterDelegate:userDriverDelegate:"),
            ObjCBool(true), nil, nil
        )
        return controller.takeRetainedValue()
    }
}
