<p align="center">
  <img src="docs/screenshots/flutterrunlet-dock-128.jpg" width="88" height="88" alt="FlutterRunlet app icon">
</p>

<h1 align="center">FlutterRunlet</h1>

<p align="center"><strong>Run and debug Flutter apps from the macOS menu bar.</strong></p>

<p align="center">
  English · <a href="README.zh-CN.md">简体中文</a> · <a href="https://github.com/atypiape/flutter-runlet/releases">Downloads</a>
</p>

FlutterRunlet is a native macOS app that reads the VS Code launch configurations and tasks already in your Flutter project. Start a debug session, hot reload, or open DevTools from the menu bar or the main window.

## Why I built it

I do most of my coding with AI tools now and rarely need VS Code for editing. But to launch and debug a Flutter app, I still had to open it for the Flutter extension. On my machine that usually meant another editor window on the desktop and about 2–3 GB of memory for an app I was only using as a debugger.

I built FlutterRunlet so I could keep my existing Flutter configurations, leave VS Code closed, and reach the debug controls from the menu bar.

## Screenshots

| Main window | Menu bar |
| :---: | :---: |
| [![FlutterRunlet main window with app, configuration, device, and logs](docs/screenshots/main-window.jpg)](docs/screenshots/main-window.jpg) | [![macOS menu bar with the FlutterRunlet panel open](docs/screenshots/menu-bar.jpg)](docs/screenshots/menu-bar.jpg) |
| **Settings** | **About** |
| [![FlutterRunlet general settings](docs/screenshots/settings.jpg)](docs/screenshots/settings.jpg) | [![About FlutterRunlet and the Check for Updates button](docs/screenshots/about.jpg)](docs/screenshots/about.jpg) |

Screenshots show a v0.2.0 development build with sample data.

## Install

**v0.2.0 has passed local acceptance testing and is not yet publicly available.** Get available builds from [GitHub Releases](https://github.com/atypiape/flutter-runlet/releases). Follow the release page's checksum instructions, open the DMG, and drag FlutterRunlet to **Applications**.

The deployment target is macOS 15.0. Universal builds include Apple Silicon and Intel. Runtime testing was done on Apple Silicon with macOS 26.7.1; running on Intel or macOS 15 has not yet been verified. See the [release notes](docs/RELEASE-NOTES.md) (Simplified Chinese).

## Start debugging

1. Install your project's Flutter SDK and get a simulator or physical device ready. In **Settings → Flutter**, check the SDK source and version. You can use the SDK on your PATH, pick one manually, or prefer the project's FVM configuration.
2. Open a Flutter project with `.vscode/launch.json`. If your launch configuration refers to tasks, include `.vscode/tasks.json` too. Select a **Debug** configuration and a device, then click **Run**.
3. Once connected, hot reload, hot restart, or open DevTools and the Inspector in your browser. The main window lets you view, copy, and clear the session log.
4. Click **Stop** and let any post-debug task finish. If environment recovery fails, reopen the affected project and use **Retry Recovery** to run the original task again.

Both views control the same session. Changing the device while debugging sets up the next run; the current session stays on its original device. The app supports English and Simplified Chinese and follows the system's light or dark appearance.

FlutterRunlet supports **Debug** configurations. Profile and Release configurations, long-running background tasks, complex interactive tasks, and some VS Code extension variables are outside its scope. It leaves your configuration files alone and runs the pre-launch and post-debug tasks you configured. Try the [sample VS Code configurations](docs/examples/sample-flutter-app/README.md) or see the [compatibility details](docs/02-TECHNICAL.md#2-launchjson-基本契约v01) (Simplified Chinese).

Use **Settings → About** or **About FlutterRunlet** to check for updates. In-app updates are available only for verified stable releases. Install pre-release builds manually.

## Development

See the [developer guide](docs/DEVELOPMENT.md) (Simplified Chinese) for building from source, running tests, and packaging.

## License

[MIT](LICENSE).
