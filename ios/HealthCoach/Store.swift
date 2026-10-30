import Foundation
import Combine

final class Store: ObservableObject {
    private let defaults = UserDefaults.standard
    private let recordsKey = "hc.records.v1"
    private let examKey = "hc.examdate.v1"
    private let reminderKey = "hc.reminders.v1"

    @Published var records: [String: DayRecord] = [:] {
        didSet { persistRecords() }
    }

    @Published var examDate: Date = Date() {
        didSet { defaults.set(examDate, forKey: examKey) }
    }

    @Published var reminders: [ReminderItem] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(reminders) {
                defaults.set(data, forKey: reminderKey)
            }
            Notifier.reschedule(reminders)
        }
    }

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    init() {
        if let data = defaults.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([String: DayRecord].self, from: data) {
            records = decoded
        } else {
            records = [:]
        }

        if let saved = defaults.object(forKey: examKey) as? Date {
            examDate = saved
        } else {
            examDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        }

        if let data = defaults.data(forKey: reminderKey),
           let decoded = try? JSONDecoder().decode([ReminderItem].self, from: data) {
            reminders = decoded
        } else {
            reminders = ReminderItem.defaults
        }
    }

    private func persistRecords() {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: recordsKey)
        }
    }

    // MARK: - 今日

    var todayKey: String { Store.dayFormatter.string(from: Date()) }

    var today: DayRecord {
        records[todayKey] ?? DayRecord(date: todayKey)
    }

    private func mutateToday(_ change: (inout DayRecord) -> Void) {
        let key = todayKey
        var rec = records[key] ?? DayRecord(date: key)
        change(&rec)
        records[key] = rec
    }

    func toggleDiet() { mutateToday { $0.diet.toggle() } }
    func toggleMeds() { mutateToday { $0.meds.toggle() } }
    func toggleSleep() { mutateToday { $0.sleep.toggle() } }

    func addWater(_ ml: Int) {
        mutateToday { $0.waterMl = max(0, $0.waterMl + ml) }
    }

    func resetWater() {
        mutateToday { $0.waterMl = 0 }
    }

    // MARK: - 统计

    var streak: Int {
        let cal = Calendar.current
        var count = 0
        var day = Date()

        if let rec = records[Store.dayFormatter.string(from: day)], rec.allDone {
            count += 1
        }

        var guardCount = 0
        while guardCount < 500 {
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
            guardCount += 1
            if let rec = records[Store.dayFormatter.string(from: day)], rec.allDone {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    var daysToExam: Int {
        let cal = Calendar.current
        let a = cal.startOfDay(for: Date())
        let b = cal.startOfDay(for: examDate)
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }

    func recentDays(_ n: Int) -> [DayStat] {
        let cal = Calendar.current
        var out: [DayStat] = []
        var offset = n - 1
        while offset >= 0 {
            if let d = cal.date(byAdding: .day, value: -offset, to: Date()) {
                let key = Store.dayFormatter.string(from: d)
                out.append(DayStat(id: key, date: d, record: records[key]))
            }
            offset -= 1
        }
        return out
    }
}
