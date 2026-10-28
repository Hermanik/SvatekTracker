# SvátekTracker

Nativní macOS menubar appka (Apple Silicon) — české jmeniny a státní svátky.
Náhrada staré `Svatek.app` (net.sandwichlab.svatek, 2010, Intel/Rosetta, Growl).
Swift + AppKit + SwiftUI, stejný vzor jako MonitorTracker.

## Build & příkazy

Vyžaduje Xcode (Swift 6.2+). Cíl: **arm64, macOS 14+**.

- Build: `swift build`
- Run (dev): `swift run SvatekTracker` — menubar přes `.accessory` policy (bez bundlu,
  tedy **bez upozornění a login itemu** — ty potřebují skutečný bundle)
- Testy: `swift test`
- Format: `swift format -r -i Sources Tests` · check: `swift format lint -r -s Sources Tests`
- Lokální `.app`: `scripts/bundle.sh` → `dist/SvátekTracker.app` (Developer ID podpis,
  když je cert v keychainu, jinak ad-hoc)
- Instalace + spuštění: `scripts/install.sh` → `/Applications/SvátekTracker.app`
- Vizuální kontrola panelu bez klikání a bez Screen Recording oprávnění:
  `SVATEKTRACKER_SNAPSHOT=/tmp/snap swift run SvatekTracker` → PNG za každou záložku
- Ikona: `swift scripts/make-icon.swift` (výstup `assets/SvatekTracker.icns` je commitnutý)

## Architektura

- `Sources/SvatekTrackerCore` — **čistá logika bez systémových závislostí**, 100% testovatelná:
  - `Day` — datum bez času a časové zóny; aritmetika v UTC (žádné DST pasti).
  - `NameDays` — kalendář jmenin (tabulka 12 × 31/29), hledání bez diakritiky, příští datum jména.
  - `Holidays` — dny pracovního klidu dle zákona 245/2000 Sb. (Velikonoce počítané),
    zavírání obchodů nad 200 m² dle zákona 223/2016 Sb.
  - `ReminderPlan` — co a kdy upozornit (rozhoduje se tady, ne v systémové vrstvě).
  - `CzechText` — české datumy, skloňování („za 3 dny“ / „za 5 dní“), výčty.
- `Sources/SvatekTracker` — executable:
  - `App/AppDelegate` — `NSStatusItem`, panel pod ikonou, pravé tlačítko = menu.
  - `App/AppModel` — dnešní den (přepíná o půlnoci, po probuzení, při změně hodin/zóny),
    hlídaná jména a nastavení v `UserDefaults`.
  - `App/Reminders` — předává `ReminderPlan` do `UNUserNotificationCenter`.
  - `UI/PopoverView` — SwiftUI panel (Jmeniny / Svátky / Hlídané).

## Pravidla

- **UI texty česky** (appka je pro český kalendář), **komentáře v kódu anglicky**.
- **Každá ikona / ikonové tlačítko má tooltip** (`.help("…")`, `toolTip` v AppKit).
- Logika patří do `SvatekTrackerCore` s testem; executable jen napojuje systém.
- Data kalendáře a svátků jsou dané zákonem / tradicí — změnu podlož zdrojem a testem.
- **Swift jazykový mód 5** (tools-version 5.9); migrace na Swift 6 vědomě, samostatným commitem.
- **arm64-only, macOS 14+.** Nové API jen za `if #available`.

## Distribuce

Open source (MIT), veřejné repo `Hermanik/SvatekTracker`. Zatím jen build ze
zdrojáků (`scripts/install.sh`). Sparkle auto-update, DMG, notarizace a download
stránka (vzor MonitorTracker/GitTracker) zatím nejsou — bundle ID
`com.hermanik.svatektracker` po prvním vydání neměnit. Screenshoty v `docs/`
jsou z `SVATEKTRACKER_SNAPSHOT`.
