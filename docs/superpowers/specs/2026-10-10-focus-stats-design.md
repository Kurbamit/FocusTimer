# Focus Stats (Day / Week / All-Time) — Design

## Goal

Show the user how much focused time they've accumulated today, over the
trailing 7 days, and ever — replacing the current bare "N sessions done"
counter with something more meaningful now that focus duration is
user-configurable.

## Scope decisions (confirmed with user)

- Metric: both focused **minutes** and **session count**, shown together.
- Only **fully completed** focus sessions count (timer reaches zero
  naturally). A session reset or abandoned partway through is not
  credited — matches existing behavior, where completion is already the
  only event that triggers the sound/notification.
- "Week" = rolling trailing 7 days (today + previous 6), not calendar
  week.
- Stats live in a **new view inside the existing menu-bar popover**
  (not the Settings window, not a separate app window), reached via a
  new icon button next to the existing gear button.
- Persistence approach: bounded daily buckets (last 7 days) + monotonic
  all-time counters — not an unbounded raw session log. No migration of
  the old `sessionsCompletedToday` / `sessionsCompletedDate`
  `UserDefaults` keys; they are simply abandoned.

## Data model & persistence — `FocusStatsStore.swift`

```swift
struct DailyFocusBucket: Codable {
    let date: Date   // Calendar.current.startOfDay(for:) — identifies the day
    var minutes: Int
    var sessionCount: Int
}

@MainActor
final class FocusStatsStore: ObservableObject {
    @Published private(set) var buckets: [DailyFocusBucket]
    @Published private(set) var allTimeMinutes: Int
    @Published private(set) var allTimeSessionCount: Int

    func recordCompletedFocusSession(minutes: Int)

    var todayMinutes: Int
    var todaySessionCount: Int
    var weekMinutes: Int
    var weekSessionCount: Int
}
```

- `buckets` is loaded from `UserDefaults` (JSON-encoded `[DailyFocusBucket]`
  under key `"focusStats.buckets"`) on init, then immediately pruned to
  entries within the trailing 7 days (handles the case where the app
  wasn't opened for a while).
- `allTimeMinutes` / `allTimeSessionCount` are plain `Int` values under
  keys `"focusStats.allTimeMinutes"` / `"focusStats.allTimeSessionCount"`.
  They are never pruned or recomputed from buckets — they are the
  permanent running total.
- `recordCompletedFocusSession(minutes:)`:
  1. Prunes `buckets` to the trailing 7 days.
  2. Finds today's bucket (`Calendar.current.isDateInToday(bucket.date)`)
     or appends a new one (`date: Calendar.current.startOfDay(for: Date())`,
     `minutes: 0`, `sessionCount: 0`).
  3. Increments that bucket's `minutes`/`sessionCount`.
  4. Increments `allTimeMinutes`/`allTimeSessionCount`.
  5. Persists `buckets` (JSON) and the two all-time `Int`s to
     `UserDefaults`.
- `todayMinutes`/`todaySessionCount`: sum over buckets where
  `Calendar.current.isDateInToday(bucket.date)` (0 if no such bucket —
  this is computed on read, not cached, so it's correct even if the app
  has been open since before midnight and no session has completed yet
  today).
- `weekMinutes`/`weekSessionCount`: sum over buckets where
  `bucket.date >= Calendar.current.date(byAdding: .day, value: -6, to:
  Calendar.current.startOfDay(for: Date()))!`.

This bounds persisted storage to at most 7 small `Codable` structs
indefinitely, while still giving an exact, never-pruned all-time total.

## Integration — `TimerViewModel.swift`

Remove: `sessionsCompletedToday` (`@Published` property), `countKey`,
`countDateKey`, `loadDailyCount()`, `incrementDailyCount()`, `statusText`.

Add: `private let stats: FocusStatsStore`, injected through
`init(settings:stats:)`.

In `completeSession()`, where `incrementDailyCount()` is currently called
(the `endedPhase == .focus` branch), call instead:

```swift
stats.recordCompletedFocusSession(minutes: Int(settings.duration(for: .focus) / 60))
```

This uses the focus duration *at the moment of completion* (today's
`AppSettings.focusMinutes`), which is correct under the "completed only"
rule — the full configured duration elapsed by definition.

## Wiring — `FocusTimerApp.swift`

Add `@StateObject private var stats = FocusStatsStore()` alongside the
existing `settings`/`viewModel`, constructed in the same `init()` pattern
already used to wire `TimerViewModel(settings:)`. Pass `stats` into
`TimerViewModel.init` and into `ContentView`.

## UI

### `ContentView.swift`

- Top row gains a second icon button (`chart.bar`, placed before the
  existing `gearshape` button) that toggles
  `@State private var isShowingStats = false`.
- When `isShowingStats` is `true`, the popover's body shows `StatsView`
  (with a `chevron.left` back button in the same top-row position,
  replacing the two icons) instead of the timer controls.
- When `false` (default), the existing timer UI is shown, but the
  bottom "N sessions done" `Text` is replaced with a `Text` sourced from
  `stats.todayMinutes` / `stats.todaySessionCount`, formatted like
  `"Today: 1h 15m · 3 sessions"`.

### `StatsView.swift` (new)

Reuses the existing `SettingsSection` card styling (already used by
`SettingsView`) for visual consistency:

```swift
SettingsSection(title: "Focus Time") {
    StatRow(title: "Today", value: ...)
    Divider().padding(.leading, 12)
    StatRow(title: "This Week", value: ...)
    Divider().padding(.leading, 12)
    StatRow(title: "All Time", value: ...)
}
```

Each `value` is formatted as `"<duration> · N session(s)"`, e.g.
`"1h 15m · 3 sessions"` or `"45m · 1 session"` (no "0h" prefix under an
hour; singular/plural "session"/"sessions").

### `StatRow.swift` (new)

A simple, non-interactive label/value row matching the visual rhythm of
the existing `StepperRow`/`ToggleRow` (same padding, same card
placement), but with no control — just two `Text`s (title left, value
right, secondary + monospaced digits on the value), since stats are
read-only.

### Duration formatting

A small helper — e.g. `static func formatted(minutes: Int) -> String`
on `FocusStatsStore` or a tiny free function next to it — converts a
minute count into `"Xh Ym"` / `"Ym"` text, shared by `StatsView` and
`ContentView`'s "Today" line.

## Error handling / edge cases

- All persistence happens only inside `recordCompletedFocusSession`,
  called once per completed focus session — no I/O inside the
  per-second `tick()` loop, preserving the current performance profile.
- Bucket pruning happens both on load (in `init`) and on every write,
  so storage never exceeds 7 entries regardless of how long the app
  has been closed or idle.
- "This week" naturally includes "today" even before any session
  completes today — it's a sum over existing buckets, not a cached
  value, so a missing today-bucket just contributes 0.

## Testing

- Build and run via `xcodebuild` + `open`, as done for prior features.
- Temporarily drop `AppSettings.focusMinutes` via the Settings UI (or
  briefly hardcode a short duration) to complete a focus session
  quickly.
- Confirm the popover's "Today" line updates immediately after
  completion, and that opening the new Stats view shows matching
  Today/Week/All-Time numbers.
- Inspect `defaults read <bundle-id> | grep focusStats` to confirm the
  new keys are written and the old `sessionsCompletedToday` /
  `sessionsCompletedDate` keys are no longer referenced by code (they
  may still linger harmlessly in `UserDefaults` from before this
  change — not cleaned up, per the "no migration" decision above).
