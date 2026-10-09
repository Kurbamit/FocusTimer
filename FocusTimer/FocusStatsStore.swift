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
