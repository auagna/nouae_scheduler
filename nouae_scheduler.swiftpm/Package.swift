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
            name: "nou ae",
            targets: ["AppModule"],
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
            additionalInfoPlistContentFilePath: "Info.plist"
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "SwiftDataApp"
        )
    ]
)
