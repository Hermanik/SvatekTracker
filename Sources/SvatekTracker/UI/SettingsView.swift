import AppKit
import ServiceManagement
import SvatekTrackerCore
import SwiftUI

/// The settings window: launch at login and the menu bar text, which reminders
/// to send, and Sparkle's background update checks.
struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var updater: Updater
    // SMAppService isn't observable: read when the window is built (it's
    // rebuilt per opening), after a toggle, and back from System Settings.
    @State private var loginStatus = LoginItem.status

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "vývojová"
    }

    var body: some View {
        Form {
            Section("Obecné") {
                Toggle(
                    "Spouštět po přihlášení",
                    isOn: Binding(
                        get: { loginStatus == .enabled },
                        set: {
                            LoginItem.setEnabled($0)
                            loginStatus = LoginItem.status
                        })
                )
                .help("SvátekTracker se spustí sám po zapnutí Macu")
                if loginStatus == .requiresApproval {
                    LabeledContent("Spouštění je zablokované v Nastavení systému") {
                        Button("Povolit…") { LoginItem.openSystemSettings() }
                            .help("Otevře Nastavení systému › Obecné › Položky otevírané po přihlášení")
                    }
                    .foregroundStyle(.orange)
                }
                Toggle("Zobrazovat jména v menu baru", isOn: $model.showNamesInMenuBar)
                    .help("Vypnuté: v menu baru zůstane jen ikona")
            }

            Section {
                Toggle("Večer předem v \(ReminderPlan.eveningHour):00", isOn: $model.remindEveningBefore)
                Toggle("Ráno v den svátku v \(ReminderPlan.morningHour):00", isOn: $model.remindMorningOf)
                Toggle("Večer předem upozornit na zavřené obchody", isOn: $model.remindShopClosures)
                    .help("Před svátky, kdy velké obchody zavírají")
            } header: {
                Text("Upozornění")
            } footer: {
                NotificationsDeniedHint(model: model)
            }

            Section("Aktualizace") {
                Toggle("Automaticky kontrolovat aktualizace", isOn: $updater.automaticallyChecks)
                    .help("Jednou denně se zeptá serveru, jestli je nová verze")
                LabeledContent("Verze \(version)") {
                    Button("Zkontrolovat teď") { updater.checkForUpdates() }
                }
            }
            .disabled(!updater.isAvailable)
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loginStatus = LoginItem.status
        }
    }
}
