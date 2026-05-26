import EventKit
import SwiftUI

struct DashboardView: View {
    @ObservedObject var eventKitManager: EventKitManager

    @State private var schedules: [EKEvent] = []
    @State private var reminders: [EKReminder] = []
    @State private var isLoading = false
    @State private var message: String?

    var body: some View {
        List {
            if let message {
                Section {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }

            Section("오늘 일정") {
                if schedules.isEmpty {
                    Text(isLoading ? "불러오는 중..." : "오늘 일정이 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(schedules.prefix(5), id: \.eventIdentifier) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)
                            Text(timeRangeText(from: event.startDate, to: event.endDate))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("오늘 할 일") {
                if reminders.isEmpty {
                    Text(isLoading ? "불러오는 중..." : "오늘 할 일이 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(reminders.prefix(5), id: \.calendarItemIdentifier) { reminder in
                        Text(reminder.title)
                    }
                }
            }
        }
        .navigationTitle("Dashboard")
        .toolbar {
            Button {
                Task { await load() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            schedules = try await eventKitManager.fetchTodaySchedules()
            reminders = try await eventKitManager.fetchTodayReminders()
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }

    private func timeRangeText(from startDate: Date, to endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}
