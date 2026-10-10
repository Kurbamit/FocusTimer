//
//  TimerViewModel.swift
//  FocusTimer
//

import AppKit
import Carbon.HIToolbox
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
    private var currentPhaseDuration: TimeInterval
    private var cancellables = Set<AnyCancellable>()
    private var startPauseHotKeyID: UInt32?

    init(settings: AppSettings, stats: FocusStatsStore) {
        self.settings = settings
        self.stats = stats
        self.timeRemaining = settings.duration(for: .focus)
        self.currentPhaseDuration = settings.duration(for: .focus)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        observeSettingsChanges()
        registerGlobalHotKey()
    }

    deinit {
        if let startPauseHotKeyID {
            GlobalHotKeyManager.shared.unregister(id: startPauseHotKeyID)
        }
    }

    /// ⌃⌥Space toggles start/pause from anywhere, without opening the popover.
    private func registerGlobalHotKey() {
        startPauseHotKeyID = GlobalHotKeyManager.shared.register(
            keyCode: UInt32(kVK_Space),
            modifiers: UInt32(controlKey | optionKey)
        ) { [weak self] in
            Task { @MainActor in
                self?.toggleStartPause()
            }
        }
    }

    private func observeSettingsChanges() {
        settings.$focusMinutes.dropFirst()
            .sink { [weak self] minutes in self?.applyDurationChange(for: .focus, minutes: minutes) }
            .store(in: &cancellables)
        settings.$shortBreakMinutes.dropFirst()
            .sink { [weak self] minutes in self?.applyDurationChange(for: .shortBreak, minutes: minutes) }
            .store(in: &cancellables)
        settings.$longBreakMinutes.dropFirst()
            .sink { [weak self] minutes in self?.applyDurationChange(for: .longBreak, minutes: minutes) }
            .store(in: &cancellables)
    }

    private func applyDurationChange(for changedPhase: SessionPhase, minutes: Int) {
        guard changedPhase == phase, !isRunning else { return }
        let duration = TimeInterval(minutes * 60)
        timeRemaining = duration
        currentPhaseDuration = duration
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
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
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
        currentPhaseDuration = timeRemaining
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
            stats.recordCompletedFocusSession(minutes: Int(currentPhaseDuration / 60))
            phase = focusSessionsInCycle >= settings.sessionsBeforeLongBreak ? .longBreak : .shortBreak
        } else {
            if endedPhase == .longBreak { focusSessionsInCycle = 0 }
            phase = .focus
        }
        timeRemaining = settings.duration(for: phase)
        currentPhaseDuration = timeRemaining
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
