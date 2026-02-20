---
description: Run the app on a specific device (lists devices first)
---
# Run App on Device

// turbo-all

1. List all available devices:
```powershell
flutter devices
```

2. Run on a specific device (replace `<device-id>` with the ID from step 1):
```powershell
flutter run -d <device-id>
```

### Common device IDs
- **Emulator**: `emulator-5554`
- **Windows desktop**: `windows`
- **Chrome**: `chrome`
- **Physical Android**: shown as a serial number like `ABCD1234`

### If emulator streamed install fails
Use direct ADB install instead:
```powershell
flutter build apk --debug
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" shell pm uninstall com.ocsafe.ocsafe_cyberguard
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" install "D:\OCSafe-Cyberguard\build\app\outputs\flutter-apk\app-debug.apk"
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" shell am start -n com.ocsafe.ocsafe_cyberguard/.MainActivity
```
