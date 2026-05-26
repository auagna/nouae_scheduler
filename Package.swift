// swift-tools-version: 5.9
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "nouae_scheduler",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "nou ae Scheduler",
            targets: ["NouAEScheduler"],
            bundleIdentifier: "com.auagna.nouae-scheduler",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .calendar),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeLeft,
                .landscapeRight,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .calendar(purposeString: "오늘 일정을 표시하고 새 일정을 Apple Calendar에 저장하기 위해 캘린더 접근 권한이 필요합니다."),
                .reminders(purposeString: "오늘 할 일을 표시하고 새 할 일을 Apple Reminders에 저장하기 위해 미리알림 접근 권한이 필요합니다.")
            ],
            additionalInfoPlistContentFilePath: "Info.plist"
        )
    ],
    targets: [
        .executableTarget(
            name: "NouAEScheduler",
            path: "Sources/NouAEScheduler"
        )
    ]
)
