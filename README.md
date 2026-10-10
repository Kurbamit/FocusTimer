# FocusTimer

A lightweight Pomodoro-style focus timer that lives in the macOS menu bar.

## Features

- Menu bar item showing the remaining time (e.g. `24:13`) while running, and an idle icon otherwise
- Click to open a small popover with the time, Start/Pause, and Reset
- Fixed cycle: 25 min focus, 5 min short break, and a 15 min long break after every 4 focus sessions
- Sound and system notification when a session ends
- Day / week / all-time focus statistics, viewable from the popover
- Settings window for customizing durations, cycle length, and alerts
- Optional "Launch at Login"
- No Dock icon — pure menu bar app

## Requirements

- macOS 26.5 or later
- Xcode 17 or later

## Building & running

```bash
open FocusTimer.xcodeproj
```

Build and run (`⌘R`) from Xcode. The app has no Dock icon or main window — look for its icon in the menu bar.

To build from the command line:

```bash
xcodebuild -project FocusTimer.xcodeproj -scheme FocusTimer -configuration Debug build
```

## Project structure

- `FocusTimer/FocusTimerApp.swift` — app entry point, `MenuBarExtra` + `Settings` scenes
- `FocusTimer/TimerViewModel.swift` — timer state machine (focus/break cycle, notifications)
- `FocusTimer/AppSettings.swift` — user-configurable settings, persisted to `UserDefaults`
- `FocusTimer/FocusStatsStore.swift` — day/week/all-time focus statistics storage
- `FocusTimer/ContentView.swift`, `TimerControlsView.swift`, `StatsView.swift`, `SettingsView.swift` — popover and settings UI

See [`MVP.md`](MVP.md) for the original feature spec.
