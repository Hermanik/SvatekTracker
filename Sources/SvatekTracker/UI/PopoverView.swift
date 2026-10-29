import AppKit
import SvatekTrackerCore
import SwiftUI

/// The dropdown under the status item: today at the top, then tabs for the
/// coming name days, public holidays, and the user's tracked names.
struct PopoverView: View {
    @ObservedObject var model: AppModel
    let openSettings: () -> Void
    @State private var tab: Tab

    enum Tab: String, CaseIterable, Identifiable {
        case nameDays = "Jmeniny"
        case holidays = "Svátky"
        case tracked = "Hlídané"

        var id: Self { self }
    }

    init(model: AppModel, tab: Tab = .nameDays, openSettings: @escaping () -> Void = {}) {
        self.model = model
        self.openSettings = openSettings
        _tab = State(initialValue: tab)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TodayHeader(model: model)

            Picker("Zobrazit", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // A fixed height keeps the panel from jumping when switching tabs.
            Group {
                switch tab {
                case .nameDays: NameDayList(model: model)
                case .holidays: HolidayList(model: model)
                case .tracked: TrackedList(model: model)
                }
            }
            .frame(height: 300)

            Divider()
            HStack {
                Button(action: openSettings) {
                    Label("Nastavení…", systemImage: "gearshape")
                }
                .help("Spouštění po přihlášení, upozornění a aktualizace (⌘,)")
                Spacer()
                Button("Ukončit") { NSApplication.shared.terminate(nil) }
                    .help("Ukončit SvátekTracker")
            }
        }
        .padding(16)
        .frame(width: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Date, who celebrates today, today's holiday, and a peek at tomorrow.
private struct TodayHeader: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let info = DayInfo(model.today)
        VStack(alignment: .leading, spacing: 6) {
            Text(CzechText.longDate(info.day))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !info.names.isEmpty {
                Text("Dnes \(CzechText.celebrates(info.names.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(CzechText.list(info.names))
                        .font(.title2.weight(.semibold))
                    if !info.celebrated(by: model.trackedNames).isEmpty {
                        TrackedStar()
                    }
                }
            } else if let note = info.note {
                Text(note)
                    .font(.title2.weight(.semibold))
            }

            if let holiday = info.holiday {
                HolidayBanner(holiday: holiday)
            }

            Text("Zítra: \(DayInfo(info.day.adding(days: 1)).title)")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct HolidayBanner: View {
    let holiday: Holiday

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "flag.fill")
                .foregroundStyle(.red)
                .help("Dnes je \(holiday.kind.label)")
            VStack(alignment: .leading, spacing: 2) {
                Text(holiday.name)
                    .font(.callout.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                Text([holiday.kind.label, holiday.shops.label].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// The next 30 days, one row each. Right-click a row to track its names.
private struct NameDayList: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(1...30, id: \.self) { offset in
                    NameDayRow(info: DayInfo(model.today.adding(days: offset)), offset: offset, model: model)
                }
            }
        }
    }
}

private struct NameDayRow: View {
    let info: DayInfo
    let offset: Int
    @ObservedObject var model: AppModel

    var body: some View {
        let tracked = !info.celebrated(by: model.trackedNames).isEmpty
        HStack(spacing: 8) {
            Text(CzechText.shortDate(info.day))
                .monospacedDigit()
                .foregroundStyle(info.day.isWeekend ? .secondary : .primary)
                .frame(width: 72, alignment: .leading)
            Text(info.title)
                .fontWeight(tracked ? .semibold : .regular)
                .foregroundStyle(info.names.isEmpty ? .secondary : .primary)
                .lineLimit(1)
            if tracked {
                TrackedStar()
            }
            if let holiday = info.holiday {
                Image(systemName: "flag.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .help(holiday.name)
            }
            Spacer()
            RelativeDays(days: offset)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .help(info.names.isEmpty ? "" : "Pravým kliknutím jméno přidáš mezi hlídané")
        .contextMenu {
            ForEach(info.names, id: \.self) { name in
                Button(model.isTracked(name) ? "Přestat hlídat \(name)" : "Hlídat \(name)") {
                    model.toggleTracked(name)
                }
            }
        }
    }
}

/// Public holidays in the coming year.
private struct HolidayList: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Holidays.upcoming(from: model.today, days: 365), id: \.self) { holiday in
                    HolidayRow(holiday: holiday, days: model.today.days(until: holiday.day))
                }
            }
        }
    }
}

private struct HolidayRow: View {
    let holiday: Holiday
    let days: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(holiday.name)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(CzechText.shortDate(holiday.day)) · \(holiday.kind.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let detail = holiday.shops.detail {
                Image(systemName: "cart.badge.minus")
                    .foregroundStyle(.orange)
                    .help(detail)
            }
            RelativeDays(days: days)
        }
        .padding(.vertical, 5)
    }
}

/// Search the calendar and star names to track; with an empty query, lists the
/// tracked names by their next name day.
private struct TrackedList: View {
    @ObservedObject var model: AppModel
    @State private var query = ""

    var body: some View {
        let names = query.isEmpty ? model.trackedNames : NameDays.search(query)
        let upcoming = NameDays.nextDates(of: names, from: model.today)

        VStack(alignment: .leading, spacing: 8) {
            TextField("Najít jméno…", text: $query)
                .textFieldStyle(.roundedBorder)

            if upcoming.isEmpty {
                Text(
                    query.isEmpty
                        ? "Vyhledej jméno a hvězdičkou ho přidej mezi hlídané — jeho svátek ti připomenu upozorněním."
                        : "Jméno „\(query)“ v kalendáři není."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(upcoming, id: \.name) { entry in
                            TrackedRow(
                                name: entry.name, day: entry.day, days: model.today.days(until: entry.day),
                                model: model)
                        }
                    }
                }
            }
            NotificationsDeniedHint(model: model)
        }
    }
}

private struct TrackedRow: View {
    let name: String
    let day: Day
    let days: Int
    @ObservedObject var model: AppModel

    var body: some View {
        let tracked = model.isTracked(name)
        HStack(spacing: 8) {
            Button {
                model.toggleTracked(name)
            } label: {
                Image(systemName: tracked ? "star.fill" : "star")
                    .foregroundStyle(tracked ? .yellow : .secondary)
            }
            .buttonStyle(.borderless)
            .help(tracked ? "Přestat hlídat \(name)" : "Hlídat \(name) — svátek ti připomenu předem")
            Text(name)
            Spacer()
            Text(CzechText.shortDate(day))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            RelativeDays(days: days)
        }
        .padding(.vertical, 4)
    }
}

/// The trailing "zítra" / "za 5 dní" column, same width in every list.
private struct RelativeDays: View {
    let days: Int

    var body: some View {
        Text(CzechText.relative(days: days))
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 64, alignment: .trailing)
    }
}

private struct TrackedStar: View {
    var body: some View {
        Image(systemName: "star.fill")
            .font(.caption)
            .foregroundStyle(.yellow)
            .help("Hlídané jméno")
    }
}

/// Shown when the user blocked notifications, which silences every reminder.
struct NotificationsDeniedHint: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if model.notificationsDenied {
            VStack(alignment: .leading, spacing: 4) {
                Label("Upozornění jsou vypnutá", systemImage: "bell.slash.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Button("Otevřít nastavení upozornění…") {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")!)
                }
                .buttonStyle(.link)
                .controlSize(.small)
                .help("Povol upozornění pro SvátekTracker v Nastavení systému")
            }
        }
    }
}
