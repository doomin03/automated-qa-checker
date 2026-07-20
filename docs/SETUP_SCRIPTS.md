# Setup Scripts

This project provides root-level setup wrappers and platform-specific setup helpers.

## Files

- `setup.sh`: root wrapper for macOS shell execution.
- `setup.bat`: root wrapper for Windows CMD or PowerShell execution.
- `scripts/setup-local.sh`: macOS local setup entry point.
- `scripts/setup-local.bat`: Windows Android/ADB helper entry point.
- `scripts/android/setup-adb.sh`: macOS/Linux ADB check and Homebrew ADB install helper.
- `scripts/android/setup-adb.bat`: Windows ADB check helper.
- `scripts/ios/setup-simulator.sh`: macOS-only Xcode, iOS Simulator, Appium XCUITest setup helper.
- `scripts/ios/check-simulator.sh`: macOS-only simulator boot/check helper.

## macOS Registration

Run once after cloning:

```bash
chmod +x setup.sh
chmod +x scripts/setup-local.sh
chmod +x scripts/android/setup-adb.sh
chmod +x scripts/ios/setup-simulator.sh
chmod +x scripts/ios/check-simulator.sh
```

If the repository is moved between Windows and macOS, run the `chmod` commands again.

## macOS Execution

Run all local setup checks:

```bash
./setup.sh
```

Run Android ADB setup only:

```bash
./scripts/android/setup-adb.sh
```

Run iOS Simulator setup only:

```bash
./scripts/ios/setup-simulator.sh
```

Check or boot a simulator:

```bash
./scripts/ios/check-simulator.sh "iPhone 15"
```

## Windows Execution

Run Android/ADB helper checks:

```bat
setup.bat
```

or from PowerShell:

```powershell
.\setup.bat
```

Run Android ADB check only:

```bat
scripts\android\setup-adb.bat
```

iOS Simulator setup is not supported on Windows. Use macOS for iOS Simulator and XCUITest setup.

## What The Scripts Do

`setup.sh` delegates to `scripts/setup-local.sh`, which checks Node.js, pnpm, Android ADB, and macOS iOS Simulator tooling.

`scripts/android/setup-adb.sh` installs ADB on macOS when Homebrew is available:

```bash
brew install --cask android-platform-tools
```

It then runs:

```bash
adb version
adb devices
```

If `emulator` is missing, it warns that Android Studio or Android SDK emulator packages are required.

`scripts/ios/setup-simulator.sh` requires macOS and checks Xcode, available simulators, Appium, and the XCUITest driver.

## Notes

- These scripts are user-run setup helpers. Normal QA commands must not auto-install global tools.
- `sudo xcodebuild -license accept` may ask for an administrator password on macOS.
- Appium installation uses `npm install -g appium` when Appium is missing.
- Android Emulator installation is not fully handled by ADB setup because emulator system images usually require Android Studio or SDK Manager setup.
