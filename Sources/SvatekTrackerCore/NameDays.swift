import Foundation

/// The Czech name-day calendar ("jmeniny").
public enum NameDays {
    /// Names celebrated on `day`; empty on the name-less days (most public
    /// holidays, plus the two days `note(on:)` labels).
    public static func names(on day: Day) -> [String] {
        parsed[day.month - 1][day.day - 1]
    }

    /// What the calendar prints on the two name-less days that aren't public
    /// holidays (those get their label from `Holidays`).
    public static func note(on day: Day) -> String? {
        switch (day.month, day.day) {
        case (1, 6): "Tři králové"
        case (11, 2): "Památka zesnulých"
        default: nil
        }
    }

    /// The first day on or after `start` when `name` is celebrated, or nil when
    /// the name isn't in the calendar. A few names have more than one day
    /// (Petr), and 29 February only comes round in leap years.
    public static func nextDate(of name: String, from start: Day) -> Day? {
        let dates = entries.filter { $0.name == name }
        guard !dates.isEmpty else { return nil }
        for year in start.year...(start.year + 8) {
            let candidates = dates.compactMap { entry -> Day? in
                guard Day.isValid(year: year, month: entry.month, day: entry.day) else { return nil }
                let day = Day(year: year, month: entry.month, day: entry.day)
                return day >= start ? day : nil
            }
            if let first = candidates.min() { return first }
        }
        return nil
    }

    /// The next name day of each of `names` on or after `start`, soonest first
    /// (ties in Czech alphabetical order); names missing from the calendar are
    /// dropped.
    public static func nextDates(of names: [String], from start: Day) -> [(name: String, day: Day)] {
        names
            .compactMap { name in nextDate(of: name, from: start).map { (name: name, day: $0) } }
            .sorted {
                $0.day != $1.day ? $0.day < $1.day : $0.name.compare($1.name, locale: czech) == .orderedAscending
            }
    }

    /// Calendar names starting with `query`, ignoring case and diacritics
    /// ("sarl" finds Šarlota), each once, in Czech alphabetical order — which
    /// puts an exact match first, as it's a prefix of every other hit.
    public static func search(_ query: String) -> [String] {
        let needle = fold(query.trimmingCharacters(in: .whitespaces))
        guard !needle.isEmpty else { return [] }
        let matches = Set(entries.map(\.name).filter { fold($0).hasPrefix(needle) })
        return matches.sorted { $0.compare($1, locale: czech) == .orderedAscending }
    }

    private static let czech = Locale(identifier: "cs_CZ")

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: czech)
    }

    /// `table` with each entry split into its names, done once.
    private static let parsed: [[[String]]] = table.map { days in
        days.map { $0.isEmpty ? [] : $0.components(separatedBy: " a ") }
    }

    /// Every (month, day, name) triple, flattened from `parsed`.
    static let entries: [(month: Int, day: Int, name: String)] = parsed.enumerated().flatMap { month, days in
        days.enumerated().flatMap { day, names in names.map { (month + 1, day + 1, $0) } }
    }

    /// One entry per day, months January…December; several names on one day are
    /// joined with " a ", and "" marks a name-less day.
    static let table: [[String]] = [
        [
            "", "Karina", "Radmila", "Diana", "Dalimil", "", "Vilma", "Čestmír", "Vladan", "Břetislav",
            "Bohdana", "Pravoslav", "Edita", "Radovan", "Alice", "Ctirad", "Drahoslav", "Vladislav", "Doubravka",
            "Ilona", "Běla", "Slavomír", "Zdeněk", "Milena", "Miloš", "Zora", "Ingrid", "Otýlie", "Zdislava",
            "Robin", "Marika",
        ],
        [
            "Hynek", "Nela", "Blažej", "Jarmila", "Dobromila", "Vanda", "Veronika", "Milada", "Apolena",
            "Mojmír", "Božena", "Slavěna", "Věnceslav", "Valentýn", "Jiřina", "Ljuba", "Miloslava", "Gizela",
            "Patrik", "Oldřich", "Lenka", "Petr", "Svatopluk", "Matěj", "Liliana", "Dorota", "Alexandr", "Lumír",
            "Horymír",
        ],
        [
            "Bedřich", "Anežka", "Kamil", "Stela", "Kazimír", "Miroslav", "Tomáš", "Gabriela", "Františka",
            "Viktorie", "Anděla", "Řehoř", "Růžena", "Rút a Matylda", "Ida", "Elena a Herbert", "Vlastimil",
            "Eduard", "Josef", "Světlana", "Radek", "Leona", "Ivona", "Gabriel", "Marián", "Emanuel", "Dita",
            "Soňa", "Taťána", "Arnošt", "Kvido",
        ],
        [
            "Hugo", "Erika", "Richard", "Ivana", "Miroslava", "Vendula", "Heřman a Hermína", "Ema", "Dušan",
            "Darja", "Izabela", "Julius", "Aleš", "Vincenc", "Anastázie", "Irena", "Rudolf", "Valérie",
            "Rostislav", "Marcela", "Alexandra", "Evženie", "Vojtěch", "Jiří", "Marek", "Oto", "Jaroslav",
            "Vlastislav", "Robert", "Blahoslav",
        ],
        [
            "", "Zikmund", "Alexej", "Květoslav", "Klaudie", "Radoslav", "Stanislav", "", "Ctibor", "Blažena",
            "Svatava", "Pankrác", "Servác", "Bonifác", "Žofie", "Přemysl", "Aneta", "Nataša", "Ivo", "Zbyšek",
            "Monika", "Emil", "Vladimír", "Jana", "Viola", "Filip", "Valdemar", "Vilém", "Maxmilián", "Ferdinand",
            "Kamila",
        ],
        [
            "Laura", "Jarmil", "Tamara", "Dalibor", "Dobroslav", "Norbert", "Iveta a Slavoj", "Medard",
            "Stanislava", "Gita", "Bruno", "Antonie", "Antonín", "Roland", "Vít", "Zbyněk", "Adolf", "Milan",
            "Leoš", "Květa", "Alois", "Pavla", "Zdeňka", "Jan", "Ivan", "Adriana", "Ladislav", "Lubomír",
            "Petr a Pavel", "Šárka",
        ],
        [
            "Jaroslava", "Patricie", "Radomír", "Prokop", "Cyril a Metoděj", "", "Bohuslava", "Nora",
            "Drahoslava", "Libuše a Amálie", "Olga", "Bořek", "Markéta", "Karolína", "Jindřich", "Luboš",
            "Martina", "Drahomíra", "Čeněk", "Ilja", "Vítězslav", "Magdaléna", "Libor", "Kristýna", "Jakub",
            "Anna", "Věroslav", "Viktor", "Marta", "Bořivoj", "Ignác",
        ],
        [
            "Oskar", "Gustav", "Miluše", "Dominik", "Kristián", "Oldřiška", "Lada", "Soběslav", "Roman",
            "Vavřinec", "Zuzana", "Klára", "Alena", "Alan", "Hana", "Jáchym", "Petra", "Helena", "Ludvík",
            "Bernard", "Johana", "Bohuslav", "Sandra", "Bartoloměj", "Radim", "Luděk", "Otakar", "Augustýn",
            "Evelína", "Vladěna", "Pavlína",
        ],
        [
            "Linda a Samuel", "Adéla", "Bronislav", "Jindřiška", "Boris", "Boleslav", "Regína", "Mariana",
            "Daniela", "Irma", "Denisa", "Marie", "Lubor", "Radka", "Jolana", "Ludmila", "Naděžda", "Kryštof",
            "Zita", "Oleg", "Matouš", "Darina", "Berta", "Jaromír", "Zlata", "Andrea", "Jonáš", "Václav",
            "Michal", "Jeroným",
        ],
        [
            "Igor", "Olívie a Oliver", "Bohumil", "František", "Eliška", "Hanuš", "Justýna", "Věra",
            "Štefan a Sára", "Marina", "Andrej", "Marcel", "Renáta", "Agáta", "Tereza", "Havel", "Hedvika",
            "Lukáš", "Michaela", "Vendelín", "Brigita", "Sabina", "Teodor", "Nina", "Beáta", "Erik",
            "Šarlota a Zoe", "", "Silvie", "Tadeáš", "Štěpánka",
        ],
        [
            "Felix", "", "Hubert", "Karel", "Miriam", "Liběna", "Saskie", "Bohumír", "Bohdan", "Evžen",
            "Martin", "Benedikt", "Tibor", "Sáva", "Leopold", "Otmar", "Mahulena", "Romana", "Alžběta", "Nikola",
            "Albert", "Cecílie", "Klement", "Emílie", "Kateřina", "Artur", "Xenie", "René", "Zina", "Ondřej",
        ],
        [
            "Iva", "Blanka", "Svatoslav", "Barbora", "Jitka", "Mikuláš", "Ambrož a Benjamín", "Květoslava",
            "Vratislav", "Julie", "Dana", "Simona", "Lucie", "Lýdie", "Radana a Radan", "Albína", "Daniel",
            "Miloslav", "Ester", "Dagmar", "Natálie", "Šimon", "Vlasta", "Adam a Eva", "", "Štěpán", "Žaneta",
            "Bohumila", "Judita", "David", "Silvestr",
        ],
    ]
}
