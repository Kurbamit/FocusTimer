# Focus Timer — MVP Spec

A lightweight Pomodoro-style focus timer that lives in the macOS menu bar.

## Platform

- macOS menu bar app (no Dock icon, no main window)
- Swift / SwiftUI, using `MenuBarExtra` (or `NSStatusItem` + `NSPopover` if targeting older macOS)

## What's in (MVP)

1. **Menu bar item**
   - Shows remaining time (e.g. `24:13`) while a session is running
   - Shows an idle icon when no session is running

2. **Popover UI**
   - Opens on click of the menu bar item
   - Shows:
     - Current time remaining
     - Start/Pause button
     - Reset button

3. **Fixed cycle**
   - 25 min focus session
   - 5 min short break
   - After every 4 focus sessions → 15 min long break
   - Cycle repeats automatically

4. **Session end feedback**
   - System notification when a session ends
   - Sound plays when a session ends

5. **Daily session counter**
   - Tracks and displays completed focus sessions for today (e.g. "3 sessions done")
   - Resets at the start of a new day

6. **Quit button**
   - Available in the popover (required since there's no Dock icon to quit from)

## Out of scope (for MVP)

- Custom durations / user-configurable intervals
- Task/project labels per session
- History, stats, or analytics beyond today's count
- Preferences window
- Launch at login toggle
- Sync across devices
