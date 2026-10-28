/// Czech wording for dates, counts, and lists. Hand-rolled rather than going
/// through Foundation's formatters: it's a few tables, and the wording stays
/// fixed across the CLDR updates that ship with each macOS release.
public enum CzechText {
    /// "středa 28. října 2026"
    public static func longDate(_ day: Day) -> String {
        "\(weekdays[day.weekday - 1]) \(day.day). \(monthsGenitive[day.month - 1]) \(day.year)"
    }

    /// "st 28. 10."
    public static func shortDate(_ day: Day) -> String {
        "\(weekdayAbbreviations[day.weekday - 1]) \(day.day). \(day.month)."
    }

    /// "dnes", "zítra", "pozítří", "za 3 dny", "za 12 dní" — for today or later.
    public static func relative(days: Int) -> String {
        switch days {
        case 0: "dnes"
        case 1: "zítra"
        case 2: "pozítří"
        // Czech plural: 2–4 → "dny", 5 and up → "dní" (1 is "zítra" above).
        default: "za \(days) \(days < 5 ? "dny" : "dní")"
        }
    }

    /// "Jana", "Petr a Pavel", "Jan, Jana a Petr"
    public static func list(_ items: [String]) -> String {
        guard let last = items.last else { return "" }
        guard items.count > 1 else { return last }
        return items.dropLast().joined(separator: ", ") + " a " + last
    }

    /// "má svátek" / "mají svátek", for "Dnes má svátek Jana".
    public static func celebrates(_ count: Int) -> String {
        count > 1 ? "mají svátek" : "má svátek"
    }

    // Indexed by `Day.weekday - 1` (Sunday first).
    private static let weekdays = ["neděle", "pondělí", "úterý", "středa", "čtvrtek", "pátek", "sobota"]
    private static let weekdayAbbreviations = ["ne", "po", "út", "st", "čt", "pá", "so"]
    private static let monthsGenitive = [
        "ledna", "února", "března", "dubna", "května", "června",
        "července", "srpna", "září", "října", "listopadu", "prosince",
    ]
}
