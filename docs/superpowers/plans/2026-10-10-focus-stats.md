# Focus Stats (Day / Week / All-Time) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the user how much focused time they've accumulated today, over the trailing 7 days, and ever, replacing the current bare "N sessions done" counter.

**Architecture:** A new `FocusStatsStore` (`ObservableObject`) persists a bounded 7-day array of daily `(minutes, sessionCount)` buckets plus two monotonic all-time counters in `UserDefaults`. `TimerViewModel` records one completed focus session into it per `completeSession()` call, replacing its old ad-hoc daily counter. The popover (`ContentView`) splits into a slim coordinator plus an extracted `TimerControlsView`, toggling to a new `StatsView` (built from the existing `SettingsSection`/row-view styling) via a new icon button.

**Tech Stack:** Swift 5 / SwiftUI, macOS `MenuBarExtra` app, deployment target macOS 26.5. No XCTest target exists in this project — every prior feature (timer logic, settings, launch-at-login) was verified via `xcodebuild build` plus launching the app and inspecting behavior/`UserDefaults` by hand. This plan follows that same convention instead of introducing a new test target mid-feature: each task's verification step is a clean `xcodebuild build`, and for user-observable changes, a manual run-through using the same `open`/`pgrep`/`defaults read` commands used throughout this project.

**Spec:** `docs/superpowers/specs/2026-10-10-focus-stats-design.md`

## Global Constraints

- Only fully completed focus sessions count toward stats (no credit for a session reset or abandoned partway through).
- "Week" means the rolling trailing 7 days (today + previous 6), not a calendar week.
- The stats UI lives inside the existing menu-bar popover — no new window, no new Settings section.
- Persistence is bounded daily buckets (trailing 7 days) plus monotonic all-time counters — not an unbounded raw session log.
- The old `sessionsCompletedToday` / `sessionsCompletedDate` `UserDefaults` keys are abandoned, not migrated.
- New icon-only buttons get an `.accessibilityLabel` (existing icon buttons in files untouched by this plan are out of scope).
- Button actions beyond a single trivial statement are extracted into private methods, not left as multi-statement inline closures (per `swiftui-pro` guidance, used for every view in this plan).

---

### Task 1: FocusStatsStore (data model + persistence)

**Files:**
- Create: `FocusTimer/FocusTimer/FocusStatsStore.swift`

**Interfaces:**
- Consumes: nothing (pure `Foundation`/`Combine`).
- Produces (used by later tasks):
  - `struct DailyFocusBucket: Codable { let date: Date; var minutes: Int; var sessionCount: Int }`
  - `@MainActor final class FocusStatsStore: ObservableObject`
    - `init()`
    - `@Published private(set) var buckets: [DailyFocusBucket]`
    - `@Published private(set) var allTimeMinutes: Int`
    - `@Published private(set) var allTimeSessionCount: Int`
    - `var todayMinutes: Int { get }`
    - `var todaySessionCount: Int { get }`
    - `var weekMinutes: Int { get }`
    - `var weekSessionCount: Int { get }`
    - `func recordCompletedFocusSession(minutes: Int)`
    - `static func formatted(minutes: Int) -> String`

- [ ] **Step 1: Write `FocusStatsStore.swift`**

```swift
//
//  FocusStatsStore.swift
//  FocusTimer
//

import Combine
import Foundation

struct DailyFocusBucket: Codable {
    let date: Date
    var minutes: Int
    var sessionCount: Int
}

@MainActor
final class FocusStatsStore: ObservableObject {
    @Published private(set) var buckets: [DailyFocusBucket]
    @Published private(set) var allTimeMinutes: Int
    @Published private(set) var allTimeSessionCount: Int

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let buckets = "focusStats.buckets"
        static let allTimeMinutes = "focusStats.allTimeMinutes"
        static let allTimeSessionCount = "focusStats.allTimeSessionCount"
    }

    init() {
        if let data = defaults.data(forKey: Keys.buckets),
           let decoded = try? JSONDecoder().decode([DailyFocusBucket].self, from: data) {
            buckets = decoded
        } else {
            buckets = []
        }
        allTimeMinutes = defaults.integer(forKey: Keys.allTimeMinutes)
        allTimeSessionCount = defaults.integer(forKey: Keys.allTimeSessionCount)
        pruneBuckets()
    }

    var todayMinutes: Int {
        buckets.first { Calendar.current.isDateInToday($0.date) }?.minutes ?? 0
    }

    var todaySessionCount: Int {
        buckets.first { Calendar.current.isDateInToday($0.date) }?.sessionCount ?? 0
    }

    var weekMinutes: Int {
        buckets.filter(isWithinTrailingWeek).reduce(0) { $0 + $1.minutes }
    }

    var weekSessionCount: Int {
        buckets.filter(isWithinTrailingWeek).reduce(0) { $0 + $1.sessionCount }
    }

    func recordCompletedFocusSession(minutes: Int) {
        pruneBuckets()

        let today = Calendar.current.startOfDay(for: Date())
        if let index = buckets.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            buckets[index].minutes += minutes
            buckets[index].sessionCount += 1
        } else {
            buckets.append(DailyFocusBucket(date: today, minutes: minutes, sessionCount: 1))
        }

        allTimeMinutes += minutes
        allTimeSessionCount += 1

        persist()
    }

    private func isWithinTrailingWeek(_ bucket: DailyFocusBucket) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        guard let weekStart = Calendar.current.date(byAdding: .day, value: -6, to: today) else {
            return false
        }
        return bucket.date >= weekStart
    }

    private func pruneBuckets() {
        buckets.removeAll { !isWithinTrailingWeek($0) }
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(buckets) {
            defaults.set(encoded, forKey: Keys.buckets)
        }
        defaults.set(allTimeMinutes, forKey: Keys.allTimeMinutes)
        defaults.set(allTimeSessionCount, forKey: Keys.allTimeSessionCount)
    }

    static func formatted(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(remainingMinutes)m"
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run:
```bash
cd "/Users/dominykas.cernovas/Documents/Documents-Dominykas's-Laptop-1/coding_projects/focus-timer/FocusTimer"
xcodebuild -project FocusTimer.xcodeproj -scheme FocusTimer -configuration Debug build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. This file is not referenced anywhere yet, so there is no runtime behavior to exercise — that comes in Task 4, once `TimerViewModel` calls `recordCompletedFocusSession`.

- [ ] **Step 3: Commit**

```bash
git add FocusTimer/FocusStatsStore.swift
git commit -m "Add FocusStatsStore for day/week/all-time focus stats persistence"
```

---

### Task 2: StatRow (reusable read-only row)

**Files:**
- Create: `FocusTimer/FocusTimer/StatRow.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `struct StatRow: View { let title: String; let value: String }`

- [ ] **Step 1: Write `StatRow.swift`**

```swift
//
//  StatRow.swift
//  FocusTimer
//

import SwiftUI

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

#Preview {
    StatRow(title: "Today", value: "1h 15m · 3 sessions")
        .padding()
        .frame(width: 320)
}
```

- [ ] **Step 2: Build to verify it compiles**

Run the same `xcodebuild` command as Task 1, Step 2.
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusTimer/StatRow.swift
git commit -m "Add StatRow for read-only stat display rows"
```

---

### Task 3: StatsView (Today / This Week / All Time card)

**Files:**
- Create: `FocusTimer/FocusTimer/StatsView.swift`

**Interfaces:**
- Consumes:
  - `SettingsSection<Content: View>` (existing, from `SettingsSection.swift`) — `init(title: String, @ViewBuilder content: () -> Content)`
  - `StatRow(title: String, value: String)` (Task 2)
  - `FocusStatsStore.todayMinutes/todaySessionCount/weekMinutes/weekSessionCount/allTimeMinutes/allTimeSessionCount: Int` and `static func formatted(minutes: Int) -> String` (Task 1)
- Produces: `struct StatsView: View { @ObservedObject var stats: FocusStatsStore }` — a bare card with no outer frame/padding, so the caller controls layout (matches how `ContentView` will place it inside the popover in Task 5).

- [ ] **Step 1: Write `StatsView.swift`**

```swift
//
//  StatsView.swift
//  FocusTimer
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var stats: FocusStatsStore

    var body: some View {
        SettingsSection(title: "Focus Time") {
            StatRow(title: "Today", value: summary(minutes: stats.todayMinutes, sessions: stats.todaySessionCount))
            Divider().padding(.leading, 12)
            StatRow(title: "This Week", value: summary(minutes: stats.weekMinutes, sessions: stats.weekSessionCount))
            Divider().padding(.leading, 12)
            StatRow(title: "All Time", value: summary(minutes: stats.allTimeMinutes, sessions: stats.allTimeSessionCount))
        }
    }

    private func summary(minutes: Int, sessions: Int) -> String {
        "\(FocusStatsStore.formatted(minutes: minutes)) · \(sessions) session\(sessions == 1 ? "" : "s")"
    }
}

#Preview {
    StatsView(stats: FocusStatsStore())
        .padding(24)
        .frame(width: 360)
}
```

- [ ] **Step 2: Build to verify it compiles**

Run the same `xcodebuild` command as Task 1, Step 2.
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusTimer/StatsView.swift
git commit -m "Add StatsView composing Today/This Week/All Time stat rows"
```

---

### Task 4: Wire FocusStatsStore into TimerViewModel and app startup

**Files:**
- Modify: `FocusTimer/FocusTimer/TimerViewModel.swift` (full rewrite — remove the old daily counter, add the `stats` dependency)
- Modify: `FocusTimer/FocusTimer/FocusTimerApp.swift` (construct and inject `FocusStatsStore`)
- Modify: `FocusTimer/FocusTimer/ContentView.swift` (minimal: accept `stats`, replace the bottom status line, fix the `#Preview` — the bigger restructuring into `TimerControlsView` happens in Task 5)

**Interfaces:**
- Consumes: `FocusStatsStore.recordCompletedFocusSession(minutes: Int)`, `.todayMinutes`, `.todaySessionCount`, `FocusStatsStore.formatted(minutes:)` (Task 1).
- Produces (changed from before):
  - `TimerViewModel.init(settings: AppSettings, stats: FocusStatsStore)` — signature gains the `stats` parameter.
  - `TimerViewModel.statusText` is **removed** (no longer exists).
  - `ContentView.init` gains a required `stats: FocusStatsStore` parameter.

- [ ] **Step 1: Rewrite `TimerViewModel.swift`**

```swift
//
//  TimerViewModel.swift
//  FocusTimer
//

import AppKit
import Combine
import Foundation
import UserNotifications

enum SessionPhase {
    case focus
    case shortBreak
    case longBreak

    var label: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var phase: SessionPhase = .focus
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var isRunning = false

    private let settings: AppSettings
    private let stats: FocusStatsStore
    private var timer: Timer?
    private var focusSessionsInCycle = 0

    init(settings: AppSettings, stats: FocusStatsStore) {
        self.settings = settings
        self.stats = stats
        self.timeRemaining = settings.duration(for: .focus)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var menuBarText: String? {
        guard isRunning else { return nil }
        return formatted(timeRemaining)
    }

    var timeRemainingText: String {
        formatted(timeRemaining)
    }

    func toggleStartPause() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        timeRemaining = settings.duration(for: phase)
    }

    private func tick() {
        guard timeRemaining > 1 else {
            completeSession()
            return
        }
        timeRemaining -= 1
    }

    private func completeSession() {
        let endedPhase = phase
        pause()
        notifySessionEnd(for: endedPhase)

        if endedPhase == .focus {
            focusSessionsInCycle += 1
            stats.recordCompletedFocusSession(minutes: Int(settings.duration(for: .focus) / 60))
            phase = focusSessionsInCycle >= settings.sessionsBeforeLongBreak ? .longBreak : .shortBreak
        } else {
            if endedPhase == .longBreak { focusSessionsInCycle = 0 }
            phase = .focus
        }
        timeRemaining = settings.duration(for: phase)
    }

    private func notifySessionEnd(for endedPhase: SessionPhase) {
        if settings.soundEnabled {
            NSSound(named: "Glass")?.play()
        }

        guard settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Focus Timer"
        content.body = "\(endedPhase.label) session ended"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
```

- [ ] **Step 2: Rewrite `FocusTimerApp.swift`**

```swift
//
//  FocusTimerApp.swift
//  FocusTimer
//
//  Created by Dominykas Cernovas on 09/10/2026.
//

import SwiftUI

@main
struct FocusTimerApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var stats: FocusStatsStore
    @StateObject private var viewModel: TimerViewModel

    init() {
        let settings = AppSettings()
        let stats = FocusStatsStore()
        _settings = StateObject(wrappedValue: settings)
        _stats = StateObject(wrappedValue: stats)
        _viewModel = StateObject(wrappedValue: TimerViewModel(settings: settings, stats: stats))
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel, stats: stats)
        } label: {
            if let text = viewModel.menuBarText {
                Text(text)
                    .font(.system(.body, design: .monospaced))
            } else {
                Image(systemName: "timer")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: settings)
        }
    }
}
```

- [ ] **Step 3: Update `ContentView.swift` (minimal — accept `stats`, replace status line)**

```swift
//
//  ContentView.swift
//  FocusTimer
//
//  Created by Dominykas Cernovas on 09/10/2026.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var stats: FocusStatsStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }

            Text(viewModel.phase.label)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(viewModel.timeRemainingText)
                .font(.system(size: 40, weight: .medium, design: .monospaced))
                .monospacedDigit()

            HStack(spacing: 12) {
                Button(viewModel.isRunning ? "Pause" : "Start") {
                    viewModel.toggleStartPause()
                }
                .keyboardShortcut(.defaultAction)

                Button("Reset") {
                    viewModel.reset()
                }
            }

            Text("Today: \(FocusStatsStore.formatted(minutes: stats.todayMinutes)) · \(stats.todaySessionCount) session\(stats.todaySessionCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(20)
        .frame(width: 220)
    }
}

#Preview {
    let settings = AppSettings()
    let stats = FocusStatsStore()
    ContentView(viewModel: TimerViewModel(settings: settings, stats: stats), stats: stats)
}
```

- [ ] **Step 4: Build to verify it compiles**

Run the same `xcodebuild` command as Task 1, Step 2.
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Launch and manually verify the recording path works end-to-end**

```bash
APP_PATH="/Users/dominykas.cernovas/Library/Developer/Xcode/DerivedData/FocusTimer-gbmbjlzkjnuryxfjrpkmkttbgpad/Build/Products/Debug/FocusTimer.app"
pkill -f "FocusTimer.app/Contents/MacOS/FocusTimer" 2>/dev/null
open "$APP_PATH"
```

Then, by hand: open the popover, open Settings (gear icon), drop "Focus" to 1 minute (the shortest the stepper allows), close Settings, click Start, and wait ~1 minute for the session to complete (the sound/notification should fire as before). Reopen the popover and confirm the bottom line now reads `Today: 1h 0m · 1 session` (minutes will read `0h 1m`/`1m`-equivalent depending on the duration you set — confirm it matches what you set, pluralized correctly).

Then confirm persistence directly:
```bash
defaults read dc.FocusTimer focusStats.allTimeMinutes
defaults read dc.FocusTimer focusStats.allTimeSessionCount
```
Expected: both values are non-zero and match what you just completed.

- [ ] **Step 6: Commit**

```bash
git add FocusTimer/TimerViewModel.swift FocusTimer/FocusTimerApp.swift FocusTimer/ContentView.swift
git commit -m "Record completed focus sessions into FocusStatsStore, retire old daily counter"
```

---

### Task 5: Add Stats navigation to the popover (TimerControlsView extraction)

Per the user's request, this task's views follow `swiftui-pro` guidance: view bodies are not broken up with computed `some View` properties — each distinct concern becomes its own `View` struct in its own file; multi-statement button actions are extracted into private methods; new icon-only buttons get an `.accessibilityLabel`.

**Files:**
- Create: `FocusTimer/FocusTimer/TimerControlsView.swift` (extracted from `ContentView`'s current body — the timer UI, now parameterized with a `onShowStats` callback)
- Modify: `FocusTimer/FocusTimer/ContentView.swift` (becomes a slim coordinator that toggles between `TimerControlsView` and `StatsView`)

**Interfaces:**
- Consumes: `TimerViewModel` (existing), `FocusStatsStore` (Task 1), `StatsView` (Task 3).
- Produces: `struct TimerControlsView: View { init(viewModel: TimerViewModel, stats: FocusStatsStore, onShowStats: @escaping () -> Void) }`.

- [ ] **Step 1: Write `TimerControlsView.swift`**

```swift
//
//  TimerControlsView.swift
//  FocusTimer
//

import AppKit
import SwiftUI

struct TimerControlsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var stats: FocusStatsStore
    @Environment(\.openSettings) private var openSettings
    let onShowStats: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onShowStats) {
                    Image(systemName: "chart.bar")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show Stats")

                Spacer()

                Button(action: openSettingsWindow) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }

            Text(viewModel.phase.label)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(viewModel.timeRemainingText)
                .font(.system(size: 40, weight: .medium, design: .monospaced))
                .monospacedDigit()

            HStack(spacing: 12) {
                Button(viewModel.isRunning ? "Pause" : "Start") {
                    viewModel.toggleStartPause()
                }
                .keyboardShortcut(.defaultAction)

                Button("Reset") {
                    viewModel.reset()
                }
            }

            Text("Today: \(FocusStatsStore.formatted(minutes: stats.todayMinutes)) · \(stats.todaySessionCount) session\(stats.todaySessionCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit", action: quit)
        }
        .padding(20)
        .frame(width: 220)
    }

    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        openSettings()
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    let settings = AppSettings()
    let stats = FocusStatsStore()
    TimerControlsView(viewModel: TimerViewModel(settings: settings, stats: stats), stats: stats, onShowStats: {})
}
```

- [ ] **Step 2: Rewrite `ContentView.swift` as a slim coordinator**

```swift
//
//  ContentView.swift
//  FocusTimer
//
//  Created by Dominykas Cernovas on 09/10/2026.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var stats: FocusStatsStore
    @State private var isShowingStats = false

    var body: some View {
        if isShowingStats {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: showTimer) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                StatsView(stats: stats)
            }
            .padding(24)
            .frame(width: 360)
        } else {
            TimerControlsView(viewModel: viewModel, stats: stats, onShowStats: showStats)
        }
    }

    private func showStats() {
        isShowingStats = true
    }

    private func showTimer() {
        isShowingStats = false
    }
}

#Preview {
    let settings = AppSettings()
    let stats = FocusStatsStore()
    ContentView(viewModel: TimerViewModel(settings: settings, stats: stats), stats: stats)
}
```

- [ ] **Step 3: Build to verify it compiles**

Run the same `xcodebuild` command as Task 1, Step 2.
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Launch and manually verify the full feature**

```bash
APP_PATH="/Users/dominykas.cernovas/Library/Developer/Xcode/DerivedData/FocusTimer-gbmbjlzkjnuryxfjrpkmkttbgpad/Build/Products/Debug/FocusTimer.app"
pkill -f "FocusTimer.app/Contents/MacOS/FocusTimer" 2>/dev/null
open "$APP_PATH"
```

By hand: open the popover — confirm there are now two icons top-left/top-right (chart.bar, gearshape). Click the chart.bar icon — confirm it swaps to the "Focus Time" card showing Today/This Week/All Time rows, each `<duration> · N session(s)`, with a back chevron at the top-left. Click the chevron — confirm it returns to the timer view. Complete another short focus session (as in Task 4, Step 5) and confirm both the "Today" line on the timer view and the "Today"/"This Week" rows in the Stats view increase consistently.

- [ ] **Step 5: Commit**

```bash
git add FocusTimer/TimerControlsView.swift FocusTimer/ContentView.swift
git commit -m "Add Stats navigation to the popover via extracted TimerControlsView"
```
