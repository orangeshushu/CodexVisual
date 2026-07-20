#define AppName "CodexVisual"
#ifndef AppVersion
#define AppVersion "1.0.17"
#endif
#define AppPublisher "orangeshushu"
#define AppExeName "CodexVisual.Windows.exe"

[Setup]
AppId={{7F2922CE-531A-48E0-93AC-F5E14D3D4B1D}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\CodexVisual
DefaultGroupName=CodexVisual
DisableProgramGroupPage=yes
OutputDir=..\..\build\windows\installer
OutputBaseFilename=CodexVisual-Windows-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#AppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "autostart"; Description: "Start CodexVisual when Windows starts"; GroupDescription: "Startup options:"; Flags: unchecked

[Files]
Source: "..\..\build\windows\CodexVisual.Windows\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\CodexVisual"; Filename: "{app}\{#AppExeName}"
Name: "{autostartup}\CodexVisual"; Filename: "{app}\{#AppExeName}"; Tasks: autostart

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch CodexVisual"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/c taskkill /IM {#AppExeName} /F"; Flags: runhidden
