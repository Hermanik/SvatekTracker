# SvátekTracker

Native macOS menubar app (Apple Silicon) for Czech name days and public holidays.

- **Menu bar** shows who celebrates today — or the holiday on name-less days.
  A flag marks public holidays, a star a tracked name.
- **Click** for today in detail, the next 30 name days, the coming year's public
  holidays (with Easter computed), and which ones close large shops.
- **Track names** (search, then star) to get a reminder the evening before and
  the morning of their name day. Opt-in heads-up the evening before shops close.
- Rolls over at midnight and after sleep; right-click for launch at login.

## Build

```sh
swift test               # core logic
scripts/install.sh       # build, install to /Applications, launch
```

See [CLAUDE.md](CLAUDE.md) for the full command list and architecture.
