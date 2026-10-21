import SwiftUI

/// A month grid with dots on days that have deadlines; the selected day's tasks and completions below.
struct CalendarView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var month = Calendar.current.dateInterval(of: .month, for: Date())!.start
    @State private var selectedDay = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)

            MonthGrid(month: month, selectedDay: $selectedDay,
                      deadlines: deadlinesByDay, finishedDays: finishedDays)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .gesture(DragGesture(minimumDistance: 30).onEnded { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        moveMonth(value.translation.width < 0 ? 1 : -1)
                    }
                })

            Divider()
            dayDetail
        }
        .background(Theme.background)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(month, format: .dateTime.month(.wide).year())
                .font(.title2.weight(.semibold))
            Spacer()
            Button("Today") {
                withAnimation(reduceMotion ? nil : .snappy) {
                    month = calendar.dateInterval(of: .month, for: Date())!.start
                    selectedDay = calendar.startOfDay(for: Date())
                }
            }
            .buttonStyle(.borderless)
            Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
                .buttonStyle(.borderless)
                .accessibilityLabel("Previous month")
            Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
                .buttonStyle(.borderless)
                .accessibilityLabel("Next month")
        }
    }

    private func moveMonth(_ by: Int) {
        withAnimation(reduceMotion ? nil : .snappy) {
            month = calendar.date(byAdding: .month, value: by, to: month)!
        }
    }

    /// Tasks with a deadline, grouped by day.
    private var deadlinesByDay: [Date: [TaskItem]] {
        Dictionary(grouping: store.sortedTasks.filter { $0.deadline != nil }) { calendar.startOfDay(for: $0.deadline!) }
    }

    private var finishedDays: Set<Date> {
        Set(store.events.filter { $0.kind == .completed }.map { calendar.startOfDay(for: $0.date) })
    }

    private var dayDetail: some View {
        let due = store.tasks(dueOn: selectedDay)
        let finished = store.completions(on: selectedDay)
        return List {
            Text(selectedDay.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.headline)
                .listRowSeparator(.hidden)
            if due.isEmpty && finished.isEmpty {
                Text(calendar.isDateInToday(selectedDay) ? "Nothing due today. Type @today on a task to plan it here."
                                                        : "Nothing due or finished this day.")
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
            }
            if !due.isEmpty {
                Text("Due").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
                ForEach(due) { task in
                    TaskRow(task: task, onToggle: {
                        withAnimation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.2)) { store.toggle(task.id) }
                    })
                    .listRowSeparator(.hidden)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: Theme.cardRadius)
                            .fill(Theme.card)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.cardStroke))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 12)
                    )
                }
            }
            if !finished.isEmpty {
                Text("Finished").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .listRowSeparator(.hidden)
                ForEach(finished) { event in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle").foregroundStyle(.green)
                        Text(event.taskTitle).foregroundStyle(.secondary)
                        Spacer()
                        Text(event.date, format: .dateTime.hour().minute())
                            .font(.caption).foregroundStyle(.tertiary).monospacedDigit()
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

/// Seven columns of days for one month. Up to three dots per day show the priority colors of the
/// tasks due; a small green check marks days you finished something.
struct MonthGrid: View {
    let month: Date
    @Binding var selectedDay: Date
    let deadlines: [Date: [TaskItem]]
    let finishedDays: Set<Date>

    private let calendar = Calendar.current

    /// Leading blanks (nil) to line the 1st up under its weekday, then each day of the month.
    private var cells: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: month)!
        let firstWeekday = calendar.component(.weekday, from: month)
        let blanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        let days = range.map { calendar.date(byAdding: .day, value: $0 - 1, to: month)! }
        return Array(repeating: nil, count: blanks) + days
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol).font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
            }
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(day: day,
                            isSelected: calendar.isDate(day, inSameDayAs: selectedDay),
                            isToday: calendar.isDateInToday(day),
                            due: deadlines[day] ?? [],
                            finishedSomething: finishedDays.contains(day))
                        .onTapGesture { selectedDay = day }
                } else {
                    Color.clear.frame(height: 38)
                }
            }
        }
    }
}

private struct DayCell: View {
    let day: Date
    let isSelected: Bool
    let isToday: Bool
    let due: [TaskItem]
    let finishedSomething: Bool

    private var hasOverdue: Bool {
        due.contains { !$0.isDone } && day < Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(day, format: .dateTime.day())
                .font(.callout.weight(isToday ? .bold : .regular))
                .monospacedDigit()
                .foregroundStyle(isSelected ? Color.white : isToday ? Color.accentColor : Color.primary)
                .frame(width: 26, height: 26)
                .background {
                    if isSelected { Circle().fill(Color.accentColor) }
                    else if isToday { Circle().stroke(Color.accentColor.opacity(0.5)) }
                }
            HStack(spacing: 2) {
                ForEach(Array(due.prefix(3).enumerated()), id: \.offset) { _, task in
                    Circle()
                        .fill(task.isDone ? Color.secondary.opacity(0.4)
                              : task.priority == .none ? Color.secondary : task.priority.color)
                        .frame(width: 5, height: 5)
                }
                if due.isEmpty && finishedSomething {
                    Image(systemName: "checkmark").font(.system(size: 6, weight: .bold)).foregroundStyle(.green)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, minHeight: 38)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var accessibilityText: String {
        var text = day.formatted(date: .complete, time: .omitted)
        if !due.isEmpty { text += ", \(due.count) due" }
        if hasOverdue { text += ", overdue" }
        if finishedSomething { text += ", finished tasks" }
        return text
    }
}
