import EventKit
import SwiftUI

@main
struct NouAESchedulerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var eventKitManager = EventKitManager()

    var body: some View {
        TabView {
            NavigationStack {
                TodayView(eventKitManager: eventKitManager)
            }
            .tabItem {
                Label("Today", systemImage: "calendar")
            }

            NavigationStack {
                InboxView(eventKitManager: eventKitManager)
            }
            .tabItem {
                Label("Inbox", systemImage: "tray")
            }

            NavigationStack {
                SettingsView(eventKitManager: eventKitManager)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

enum ScheduleCategory: String, CaseIterable, Identifiable {
    case work = "작업"
    case company = "회사"
    case personal = "개인"
    case social = "소셜"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .work:
            return .blue
        case .company:
            return .purple
        case .personal:
            return .green
        case .social:
            return .orange
        }
    }

    var symbolName: String {
        switch self {
        case .work:
            return "checklist"
        case .company:
            return "building.2"
        case .personal:
            return "person"
        case .social:
            return "person.2"
        }
    }
}

@MainActor
final class EventKitManager: ObservableObject {
    @Published private(set) var calendarStatusText = "확인 필요"
    @Published private(set) var remindersStatusText = "확인 필요"

    private let eventStore = EKEventStore()

    init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        calendarStatusText = statusText(for: EKEventStore.authorizationStatus(for: .event))
        remindersStatusText = statusText(for: EKEventStore.authorizationStatus(for: .reminder))
    }

    func requestCalendarAccess() async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        refreshAuthorizationStatus()

        if !granted {
            throw EventKitManagerError.accessDenied("캘린더 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.")
        }
    }

    func requestRemindersAccess() async throws {
        let granted = try await eventStore.requestFullAccessToReminders()
        refreshAuthorizationStatus()

        if !granted {
            throw EventKitManagerError.accessDenied("미리알림 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.")
        }
    }

    func createSchedule(title: String, startDate: Date, endDate: Date, category: ScheduleCategory) async throws {
        try ensureCalendarAccess()

        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw EventKitManagerError.validation("일정 제목을 입력해 주세요.")
        }

        guard endDate > startDate else {
            throw EventKitManagerError.validation("종료 시간은 시작 시간보다 늦어야 합니다.")
        }

        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw EventKitManagerError.unavailable("기본 캘린더를 찾을 수 없습니다.")
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "[\(category.rawValue)] \(title)"
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = calendar

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw EventKitManagerError.saveFailed("일정 저장에 실패했습니다: \(error.localizedDescription)")
        }
    }

    func createReminder(title: String, dueDate: Date, category: ScheduleCategory) async throws {
        try ensureReminderAccess()

        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw EventKitManagerError.validation("할 일 제목을 입력해 주세요.")
        }

        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw EventKitManagerError.unavailable("기본 미리알림 목록을 찾을 수 없습니다.")
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = "[\(category.rawValue)] \(title)"
        reminder.calendar = calendar
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)

        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            throw EventKitManagerError.saveFailed("미리알림 저장에 실패했습니다: \(error.localizedDescription)")
        }
    }

    func fetchTodaySchedules() async throws -> [EKEvent] {
        try ensureCalendarAccess()

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    func fetchTodayReminders() async throws -> [EKReminder] {
        try ensureReminderAccess()

        let predicate = eventStore.predicateForReminders(in: nil)
        let reminders = await fetchReminders(matching: predicate)
        let calendar = Calendar.current

        return reminders
            .filter { reminder in
                guard !reminder.isCompleted,
                      let components = reminder.dueDateComponents,
                      let dueDate = calendar.date(from: components) else {
                    return false
                }
                return calendar.isDateInToday(dueDate)
            }
            .sorted { first, second in
                let firstDate = first.dueDateComponents.flatMap { calendar.date(from: $0) } ?? .distantFuture
                let secondDate = second.dueDateComponents.flatMap { calendar.date(from: $0) } ?? .distantFuture
                return firstDate < secondDate
            }
    }

    private func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
        await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private func ensureCalendarAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        if !isGranted(status) {
            throw EventKitManagerError.accessDenied("캘린더 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.")
        }
    }

    private func ensureReminderAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if !isGranted(status) {
            throw EventKitManagerError.accessDenied("미리알림 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.")
        }
    }

    private func isGranted(_ status: EKAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .fullAccess:
            return true
        case .writeOnly, .notDetermined, .restricted, .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func statusText(for status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "아직 요청하지 않음"
        case .restricted:
            return "제한됨"
        case .denied:
            return "거부됨"
        case .authorized:
            return "허용됨"
        case .fullAccess:
            return "전체 접근 허용"
        case .writeOnly:
            return "쓰기 전용"
        @unknown default:
            return "알 수 없음"
        }
    }
}

enum EventKitManagerError: LocalizedError {
    case accessDenied(String)
    case validation(String)
    case unavailable(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied(let message), .validation(let message), .unavailable(let message), .saveFailed(let message):
            return message
        }
    }
}

struct CategoryPicker: View {
    @Binding var selectedCategory: ScheduleCategory

    var body: some View {
        Picker("카테고리", selection: $selectedCategory) {
            ForEach(ScheduleCategory.allCases) { category in
                Label(category.rawValue, systemImage: category.symbolName)
                    .tag(category)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct TodayView: View {
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
                    ForEach(schedules, id: \.eventIdentifier) { event in
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
                    ForEach(reminders, id: \.calendarItemIdentifier) { reminder in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reminder.title)
                                .font(.headline)
                            if let dueText = dueDateText(for: reminder) {
                                Text(dueText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Today")
        .toolbar {
            Button {
                Task {
                    await loadTodayItems()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
        .task {
            await loadTodayItems()
        }
    }

    private func loadTodayItems() async {
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

    private func dueDateText(for reminder: EKReminder) -> String? {
        guard let components = reminder.dueDateComponents,
              let date = Calendar.current.date(from: components) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "마감 \(formatter.string(from: date))"
    }
}

struct InboxView: View {
    @ObservedObject var eventKitManager: EventKitManager

    @State private var isShowingAddSchedule = false
    @State private var isShowingAddReminder = false

    var body: some View {
        List {
            Section {
                Button {
                    isShowingAddSchedule = true
                } label: {
                    Label("빠른 일정 추가", systemImage: "calendar.badge.plus")
                }

                Button {
                    isShowingAddReminder = true
                } label: {
                    Label("빠른 할 일 추가", systemImage: "checklist")
                }
            }
        }
        .navigationTitle("Inbox")
        .sheet(isPresented: $isShowingAddSchedule) {
            NavigationStack {
                AddScheduleView(eventKitManager: eventKitManager)
            }
        }
        .sheet(isPresented: $isShowingAddReminder) {
            NavigationStack {
                AddReminderView(eventKitManager: eventKitManager)
            }
        }
    }
}

struct AddScheduleView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var category: ScheduleCategory = .work
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("일정") {
                TextField("제목", text: $title)
                DatePicker("시작", selection: $startDate)
                DatePicker("종료", selection: $endDate)
            }

            Section("카테고리") {
                CategoryPicker(selectedCategory: $category)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("일정 추가")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "저장 중" : "저장") {
                    Task {
                        await save()
                    }
                }
                .disabled(isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await eventKitManager.createSchedule(title: title, startDate: startDate, endDate: endDate, category: category)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AddReminderView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var dueDate = Date()
    @State private var category: ScheduleCategory = .work
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("할 일") {
                TextField("제목", text: $title)
                DatePicker("마감일", selection: $dueDate)
            }

            Section("카테고리") {
                CategoryPicker(selectedCategory: $category)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("할 일 추가")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "저장 중" : "저장") {
                    Task {
                        await save()
                    }
                }
                .disabled(isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await eventKitManager.createReminder(title: title, dueDate: dueDate, category: category)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SettingsView: View {
    @ObservedObject var eventKitManager: EventKitManager

    @State private var message: String?

    var body: some View {
        List {
            Section("권한 상태") {
                LabeledContent("캘린더", value: eventKitManager.calendarStatusText)
                LabeledContent("미리알림", value: eventKitManager.remindersStatusText)
            }

            Section {
                Button {
                    Task {
                        await requestCalendarAccess()
                    }
                } label: {
                    Label("캘린더 권한 요청", systemImage: "calendar")
                }

                Button {
                    Task {
                        await requestRemindersAccess()
                    }
                } label: {
                    Label("미리알림 권한 요청", systemImage: "checklist")
                }
            }

            if let message {
                Section {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            Button {
                eventKitManager.refreshAuthorizationStatus()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }

    private func requestCalendarAccess() async {
        do {
            try await eventKitManager.requestCalendarAccess()
            message = "캘린더 권한이 허용되었습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func requestRemindersAccess() async {
        do {
            try await eventKitManager.requestRemindersAccess()
            message = "미리알림 권한이 허용되었습니다."
        } catch {
            message = error.localizedDescription
        }
    }
}
