# OCSafe-Cyberguard
## Getting Started

### Prerequisites

Before running the application, ensure you have:

- Flutter SDK (latest stable version)
- Dart SDK (included with Flutter)
- Android Studio or VS Code
- Android SDK
- A connected Android device or emulator

Verify your setup:

```bash
flutter doctor
```

### Installation

1. Extract or clone the project.
2. Open the project directory.
3. Install dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

### Build Release APK

```bash
flutter build apk --release
```

The generated APK will be located at:

```
build/app/outputs/flutter-apk/app-release.apk
```

### Supported Platforms

- Android
- Windows
- iOS (additional platform-specific configuration may be required)

### Troubleshooting

If you encounter dependency issues:

```bash
flutter clean
flutter pub get
```

Then rebuild the project.

You can also verify your Flutter installation by running:

```bash
flutter doctor
```