import SwiftUI

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
                    Task { await requestCalendarAccess() }
                } label: {
                    Label("캘린더 권한 요청", systemImage: "calendar")
                }

                Button {
                    Task { await requestRemindersAccess() }
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
