/// A Czech public holiday — a day off under zákon č. 245/2000 Sb.
public struct Holiday: Hashable, Sendable {
    public enum Kind: Sendable {
        /// "Státní svátek" — commemorates the state (28 October…).
        case state
        /// "Ostatní svátek" — the remaining days off (Christmas, Easter, 1 May…).
        case other

        public var label: String {
            switch self {
            case .state: "státní svátek"
            case .other: "ostatní svátek"
            }
        }
    }

    /// Opening of shops over 200 m² under zákon č. 223/2016 Sb.
    public enum Shops: Sendable {
        case open
        case closed
        case closedFromNoon

        /// Short form for the holiday banner and list; nil when the shops are open.
        public var label: String? {
            switch self {
            case .open: nil
            case .closed: "velké obchody zavřené"
            case .closedFromNoon: "velké obchody zavřené od 12:00"
            }
        }

        /// Full sentence for tooltips; nil when the shops are open.
        public var detail: String? {
            switch self {
            case .open: nil
            case .closed: "Obchody nad 200 m² mají zavřeno"
            case .closedFromNoon: "Obchody nad 200 m² zavírají ve 12:00"
            }
        }
    }

    public let day: Day
    public let name: String
    /// Fits the menu bar on days that have no name day.
    public let shortName: String
    public let kind: Kind
    public let shops: Shops

    /// `shortName` defaults to `name` for the holidays whose name is short already.
    init(day: Day, name: String, shortName: String? = nil, kind: Kind, shops: Shops) {
        self.day = day
        self.name = name
        self.shortName = shortName ?? name
        self.kind = kind
        self.shops = shops
    }
}

public enum Holidays {
    /// The year's public holidays in date order.
    static func all(in year: Int) -> [Holiday] {
        let easter = easterSunday(year)
        func on(_ month: Int, _ day: Int) -> Day { Day(year: year, month: month, day: day) }
        return [
            Holiday(
                day: on(1, 1), name: "Nový rok a Den obnovy samostatného českého státu", shortName: "Nový rok",
                kind: .state, shops: .closed),
            Holiday(
                day: easter.adding(days: -2), name: "Velký pátek", kind: .other, shops: .open),
            Holiday(
                day: easter.adding(days: 1), name: "Velikonoční pondělí",
                kind: .other, shops: .closed),
            Holiday(day: on(5, 1), name: "Svátek práce", kind: .other, shops: .open),
            Holiday(day: on(5, 8), name: "Den vítězství", kind: .state, shops: .closed),
            Holiday(
                day: on(7, 5), name: "Den slovanských věrozvěstů Cyrila a Metoděje", shortName: "Cyril a Metoděj",
                kind: .state, shops: .open),
            Holiday(
                day: on(7, 6), name: "Den upálení mistra Jana Husa", shortName: "Mistr Jan Hus", kind: .state,
                shops: .open),
            Holiday(
                day: on(9, 28), name: "Den české státnosti", kind: .state,
                shops: .closed),
            Holiday(
                day: on(10, 28), name: "Den vzniku samostatného československého státu",
                shortName: "Vznik Československa", kind: .state, shops: .closed),
            Holiday(
                day: on(11, 17), name: "Den boje za svobodu a demokracii a Mezinárodní den studentstva",
                shortName: "17. listopad", kind: .state, shops: .open),
            Holiday(day: on(12, 24), name: "Štědrý den", kind: .other, shops: .closedFromNoon),
            Holiday(
                day: on(12, 25), name: "1. svátek vánoční", shortName: "Boží hod vánoční", kind: .other,
                shops: .closed),
            Holiday(
                day: on(12, 26), name: "2. svátek vánoční", shortName: "Štěpán", kind: .other, shops: .closed),
        ]
    }

    /// The holiday on `day`, if any. Never more than one: the fixed dates are
    /// distinct and the Easter ones (20 March – 26 April) miss them all.
    public static func on(_ day: Day) -> Holiday? {
        all(in: day.year).first { $0.day == day }
    }

    /// Holidays in the `days`-long window starting at (and including) `start`.
    public static func upcoming(from start: Day, days: Int) -> [Holiday] {
        let end = start.adding(days: days)
        return (start.year...end.year).flatMap(all(in:)).filter { $0.day >= start && $0.day < end }
    }

    /// Western (Gregorian) Easter Sunday — the anonymous Gregorian algorithm
    /// (Meeus/Jones/Butcher). Good Friday and Easter Monday hang off it.
    static func easterSunday(_ year: Int) -> Day {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let n = h + l - 7 * m + 114
        return Day(year: year, month: n / 31, day: n % 31 + 1)
    }
}
