//
//  AppSettings.swift
//  FocusTimer
//

import Combine
import Foundation
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
    @Published var launchAtLoginEnabled: Bool {
        didSet {
            guard launchAtLoginEnabled != oldValue else { return }
            do {
                if launchAtLoginEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update Launch at Login: \(error)")
            }
        }
    }
    @Published var focusMinutes: Int {
        didSet { defaults.set(focusMinutes, forKey: Keys.focusMinutes) }
    }
    @Published var shortBreakMinutes: Int {
        didSet { defaults.set(shortBreakMinutes, forKey: Keys.shortBreakMinutes) }
    }
    @Published var longBreakMinutes: Int {
        didSet { defaults.set(longBreakMinutes, forKey: Keys.longBreakMinutes) }
    }
    @Published var sessionsBeforeLongBreak: Int {
        didSet { defaults.set(sessionsBeforeLongBreak, forKey: Keys.sessionsBeforeLongBreak) }
    }
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let focusMinutes = "settings.focusMinutes"
        static let shortBreakMinutes = "settings.shortBreakMinutes"
        static let longBreakMinutes = "settings.longBreakMinutes"
        static let sessionsBeforeLongBreak = "settings.sessionsBeforeLongBreak"
        static let soundEnabled = "settings.soundEnabled"
        static let notificationsEnabled = "settings.notificationsEnabled"
    }

    init() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        focusMinutes = defaults.object(forKey: Keys.focusMinutes) as? Int ?? 25
        shortBreakMinutes = defaults.object(forKey: Keys.shortBreakMinutes) as? Int ?? 5
        longBreakMinutes = defaults.object(forKey: Keys.longBreakMinutes) as? Int ?? 15
        sessionsBeforeLongBreak = defaults.object(forKey: Keys.sessionsBeforeLongBreak) as? Int ?? 4
        soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
    }

    func duration(for phase: SessionPhase) -> TimeInterval {
        switch phase {
        case .focus: return TimeInterval(focusMinutes * 60)
        case .shortBreak: return TimeInterval(shortBreakMinutes * 60)
        case .longBreak: return TimeInterval(longBreakMinutes * 60)
        }
    }
}
