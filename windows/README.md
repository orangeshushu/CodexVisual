# CodexVisual Windows

This folder contains the Windows version of CodexVisual.

## Download

Download the latest Windows executable:

[CodexVisual-Windows.exe](https://github.com/orangeshushu/CodexVisual/releases/latest/download/CodexVisual-Windows.exe)

## Project

- App project: `CodexVisual.Windows`
- Installer script: `installer/CodexVisual.Windows.iss`
- Build script: `../scripts/build_windows.ps1`
- Installer build script: `../scripts/package_windows_inno.ps1`

The Windows app uses C# + .NET 8, WPF, WinForms `NotifyIcon`, and `Microsoft.Data.Sqlite`.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File ..\scripts\build_windows.ps1
```

The published app is written to:

```text
build\windows\CodexVisual.Windows
```

## Behavior

- Shows a draggable quota bar near the Windows taskbar.
- Left-click and drag moves the bar.
- Right-click opens the menu for quota details, refresh, Windows-only update checks, language, start-at-login, and exit.
- Reads latest valid Codex quota from local Codex sessions first, then falls back to local SQLite logs.
- Ignores expired quota events.
