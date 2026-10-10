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
    private var currentPhaseDuration: TimeInterval

    init(settings: AppSettings, stats: FocusStatsStore) {
        self.settings = settings
        self.stats = stats
        self.timeRemaining = settings.duration(for: .focus)
        self.currentPhaseDuration = settings.duration(for: .focus)
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
