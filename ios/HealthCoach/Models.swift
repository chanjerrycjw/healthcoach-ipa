import Foundation

struct DayRecord: Codable, Identifiable {
    var date: String
    var diet: Bool
    var waterMl: Int
    var meds: Bool
    var sleep: Bool

    var id: String { date }

    init(date: String, diet: Bool = false, waterMl: Int = 0, meds: Bool = false, sleep: Bool = false) {
        self.date = date
        self.diet = diet
        self.waterMl = waterMl
        self.meds = meds
        self.sleep = sleep
    }

    var waterOK: Bool { waterMl >= 1500 }

    var score: Int {
        var s = 0
        if diet { s += 1 }
        if waterOK { s += 1 }
        if meds { s += 1 }
        if sleep { s += 1 }
        return s
    }

    var allDone: Bool { score == 4 }
}

struct DayStat: Identifiable {
    let id: String
    let date: Date
    let record: DayRecord?
}

struct ReminderItem: Codable, Identifiable {
    var id: String
    var hour: Int
    var minute: Int
    var title: String
    var body: String
    var enabled: Bool

    var timeText: String {
        String(format: "%02d:%02d", hour, minute)
    }

    static let defaults: [ReminderItem] = [
        ReminderItem(id: "morning", hour: 8, minute: 30,
                     title: "今日体检准备",
                     body: "饮食控糖油、忌海鲜内脏；水喝够 1500-2000ml；保健品停了吗？",
                     enabled: true),
        ReminderItem(id: "afternoon", hour: 15, minute: 0,
                     title: "喝水抽查",
                     body: "到现在喝了多少？没过半就现在补 300ml。今天碰海鲜内脏了吗？",
                     enabled: true),
        ReminderItem(id: "night", hour: 22, minute: 50,
                     title: "该收尾了",
                     body: "距离 23:00 还有 10 分钟。今天四项做到几项？",
                     enabled: true)
    ]
}
