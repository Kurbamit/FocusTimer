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

    var duration: TimeInterval {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }

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
    @Published private(set) var timeRemaining: TimeInterval = SessionPhase.focus.duration
    @Published private(set) var isRunning = false
    @Published private(set) var sessionsCompletedToday = 0

    private var timer: Timer?
    private var focusSessionsInCycle = 0

    private let defaults = UserDefaults.standard
    private let countKey = "sessionsCompletedToday"
    private let countDateKey = "sessionsCompletedDate"

    init() {
        loadDailyCount()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var menuBarText: String? {
        guard isRunning else { return nil }
        return formatted(timeRemaining)
    }

    var timeRemainingText: String {
        formatted(timeRemaining)
    }

    var statusText: String {
        "\(sessionsCompletedToday) session\(sessionsCompletedToday == 1 ? "" : "s") done"
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
        timeRemaining = phase.duration
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
            incrementDailyCount()
            phase = focusSessionsInCycle >= 4 ? .longBreak : .shortBreak
        } else {
            if endedPhase == .longBreak { focusSessionsInCycle = 0 }
            phase = .focus
        }
        timeRemaining = phase.duration
    }

    private func notifySessionEnd(for endedPhase: SessionPhase) {
        NSSound(named: "Glass")?.play()

        let content = UNMutableNotificationContent()
        content.title = "Focus Timer"
        content.body = "\(endedPhase.label) session ended"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func incrementDailyCount() {
        loadDailyCount()
        sessionsCompletedToday += 1
        defaults.set(sessionsCompletedToday, forKey: countKey)
        defaults.set(Date(), forKey: countDateKey)
    }

    private func loadDailyCount() {
        if let savedDate = defaults.object(forKey: countDateKey) as? Date,
           Calendar.current.isDateInToday(savedDate) {
            sessionsCompletedToday = defaults.integer(forKey: countKey)
        } else {
            sessionsCompletedToday = 0
        }
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
