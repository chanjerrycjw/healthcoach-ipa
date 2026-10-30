import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var store: Store

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "E"
        return f
    }()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    countdownCard
                    todayCard
                    streakCard
                    weekCard
                    reminderCard
                    examDateCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationBarTitle("体检督导", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            Notifier.requestAuth()
            Notifier.reschedule(store.reminders)
        }
    }

    // MARK: - 卡片

    private var countdownCard: some View {
        let left = store.daysToExam
        let score = store.today.score
        return CardView("体检倒计时") {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(left >= 0 ? "\(left)" : "已过")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(left >= 0 && left <= 3 ? Color.orange : Color.primary)
                Text(left >= 0 ? "天" : "")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("今日 \(score)/4")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(score == 4 ? Color.green : Color.secondary)
                    Text(score == 4 ? "全达标" : "还差 \(4 - score) 项")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var todayCard: some View {
        CardView("今日四项") {
            VStack(spacing: 0) {
                checkRow("饮食", "控糖油 · 忌海鲜内脏 · 多吃菜", store.today.diet) {
                    store.toggleDiet()
                }
                Divider()
                waterRow
                Divider()
                checkRow("停药", "保健品 / 非必需药已停", store.today.meds) {
                    store.toggleMeds()
                }
                Divider()
                checkRow("睡眠", "23:00 前入睡", store.today.sleep) {
                    store.toggleSleep()
                }
            }
        }
    }

    private var streakCard: some View {
        CardView("连续全达标") {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(store.streak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(store.streak > 0 ? Color.green : Color.primary)
                Text("天").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text(hintText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var hintText: String {
        switch store.streak {
        case 0: return "先拿到第一天"
        case 1, 2: return "别断在这里"
        case 3...6: return "习惯开始形成"
        default: return "保持住"
        }
    }

    private var weekCard: some View {
        CardView("近 7 天") {
            HStack(spacing: 6) {
                ForEach(store.recentDays(7)) { stat in
                    VStack(spacing: 5) {
                        Text(ContentView.weekdayFormatter.string(from: stat.date))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(barColor(stat.record))
                                .frame(height: 36)
                            Text(stat.record.map { "\($0.score)" } ?? "–")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var reminderCard: some View {
        CardView("每日提醒") {
            VStack(spacing: 0) {
                ForEach(store.reminders) { item in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(item.timeText)
                                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                Text(item.title)
                                    .font(.subheadline)
                            }
                            Text(item.body)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Toggle("", isOn: Binding(
                            get: { item.enabled },
                            set: { newValue in
                                var copy = store.reminders
                                if let i = copy.firstIndex(where: { $0.id == item.id }) {
                                    copy[i].enabled = newValue
                                    store.reminders = copy
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 6)
                    if item.id != store.reminders.last?.id {
                        Divider()
                    }
                }
                Text("首次使用请允许通知权限，勿扰模式下通知会静音。")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }

    private var examDateCard: some View {
        CardView("体检日期") {
            HStack {
                Text("设定后自动计算倒计时")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                DatePicker("",
                           selection: Binding(
                            get: { store.examDate },
                            set: { store.examDate = $0 }
                           ),
                           displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(CompactDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }
        }
    }

    // MARK: - 组件

    private func checkRow(_ title: String, _ detail: String, _ on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(on ? Color.green : Color(UIColor.tertiaryLabel))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    private var waterRow: some View {
        let ml = store.today.waterMl
        let ok = ml >= 1500
        return HStack(spacing: 12) {
            Image(systemName: ok ? "checkmark.circle.fill" : "drop.circle")
                .font(.system(size: 22))
                .foregroundColor(ok ? Color.green : Color.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("喝水").font(.body)
                Text("\(ml) / 1500-2000 ml").font(.caption).foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            Button(action: { store.addWater(-300) }) {
                Text("−300")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.tertiarySystemFill))
                    .foregroundColor(.secondary)
                    .cornerRadius(7)
            }
            .buttonStyle(BorderlessButtonStyle())

            Button(action: { store.addWater(300) }) {
                Text("+300")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.13))
                    .foregroundColor(.blue)
                    .cornerRadius(7)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 9)
    }

    private func barColor(_ record: DayRecord?) -> Color {
        guard let record = record else {
            return Color(UIColor.tertiarySystemFill)
        }
        switch record.score {
        case 4: return Color.green.opacity(0.30)
        case 2, 3: return Color.orange.opacity(0.30)
        default: return Color.red.opacity(0.20)
        }
    }
}

struct CardView<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}
