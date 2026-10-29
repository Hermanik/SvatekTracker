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
- Ostrý release (Developer ID + notarizace + auto-update): bumpni `VERSION`, pak
  `scripts/release-dmg.sh` — viz **Release & distribuce**.
- Vizuální kontrola panelu bez klikání a bez Screen Recording oprávnění:
  `SVATEKTRACKER_SNAPSHOT=/tmp/snap swift run SvatekTracker` → PNG za každou záložku
  + `settings.png`
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
  - `App/AppDelegate` — `NSStatusItem`, panel pod ikonou, pravé tlačítko = menu,
    okno nastavení.
  - `App/AppModel` — dnešní den (přepíná o půlnoci, po probuzení, při změně hodin/zóny),
    hlídaná jména a nastavení v `UserDefaults`.
  - `App/Reminders` — předává `ReminderPlan` do `UNUserNotificationCenter`.
  - `App/LoginItem` — spouštění po přihlášení (`SMAppService`); první start
    z `/Applications` ho jednou zapne, pak rozhoduje uživatel.
  - `App/Updater` — Sparkle přes dlopen (bez linkování; `swift run` = no-op).
  - `UI/PopoverView` — SwiftUI panel (Jmeniny / Svátky / Hlídané).
  - `UI/SettingsView` — okno nastavení (⚙︎ v panelu / pravé tlačítko → Nastavení…).

## Pravidla

- **UI texty česky** (appka je pro český kalendář), **komentáře v kódu anglicky**.
- **Každá ikona / ikonové tlačítko má tooltip** (`.help("…")`, `toolTip` v AppKit).
- Logika patří do `SvatekTrackerCore` s testem; executable jen napojuje systém.
- Data kalendáře a svátků jsou dané zákonem / tradicí — změnu podlož zdrojem a testem.
- **Swift jazykový mód 5** (tools-version 5.9); migrace na Swift 6 vědomě, samostatným commitem.
- **arm64-only, macOS 14+.** Nové API jen za `if #available`.

## Release & distribuce

Open source (MIT), veřejné repo `Hermanik/SvatekTracker` — **adresa serveru, SSH
klíč ani nic citlivého nepatří do gitu**. Pipeline zděděná z ostatních *Tracker appek:

- **Ostrý release:** bumpni `VERSION`, pak `scripts/release-dmg.sh`: release build →
  Developer ID podpis (Sparkle inside-out, **nikdy `--deep`**) → notarizace
  (`gittracker-notary` profil, team-scoped) + staple → EdDSA appcast → rsync na update
  host + překlopení `SvatekTracker-latest.dmg` + download stránka `site/`.
- **Cíl publikace** (`UPDATE_HOST`, `UPDATE_SSH_KEY`) je v lokálním, gitignorovaném
  `.release.env` (čte ho i `stats.sh`).
- **Verze:** jediný zdroj = `VERSION` (skripty čtou, bundle stampuje do Info.plist).
- **Auto-update:** Sparkle 2.9.3 (dlopen z `vendor/`, `scripts/fetch-sparkle.sh` —
  gitignored, build/CI ho nepotřebuje). Feed
  `updates.jsemkoder.cz/svatektracker/appcast.xml` a bundle ID
  `com.hermanik.svatektracker` jsou **zapečené v Info.plist — po vydání neměnit**.
- **Sparkle klíč je vlastní pro tuhle appku:** keychain account `svatektracker`
  (`generate_appcast --account svatektracker`). Nepoužívej výchozí ani cizí account —
  sdílený klíč by při rotaci rozbil jinou appku. Ztráta klíče = konec aktualizací.
- **Server:** kontejner `svatektracker-updates` (nginx za Traefikem, `svt*` routery) —
  `scripts/setup-update-host.sh`; DNS `svatektracker.jsemkoder.cz` = A záznam bez proxy.
- **Web:** `site/index.html` (`{{VERSION}}` se stampuje při release), náhled pro sdílení
  `site/og.png` z `site/og-image.html` přes `scripts/make-og.sh`. Screenshoty v `docs/`
  jsou z `SVATEKTRACKER_SNAPSHOT`; `site/screenshot.png` je symlink na `docs/jmeniny.png`.

## Analytika

Žádná telemetrie v appce — vše z nginx access logů update hostu (Sparkle dělá denní
check na appcast). `scripts/analytics/` běží na serveru (GoAccess, cron po 15 min),
`scripts/stats.sh` lokálně stáhne report a vypíše souhrn.
