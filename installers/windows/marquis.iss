; Marquis Inno Setup Script
; Pass /DAppVersion=X.Y.Z when compiling

[Setup]
AppName=Marquis
AppVersion={#AppVersion}
AppPublisher=Marquis
DefaultDirName={autopf}\Marquis
DefaultGroupName=Marquis
UninstallDisplayIcon={app}\marquis.exe
OutputDir=..\..\build\installer
OutputBaseFilename=Marquis-windows-setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
ChangesAssociations=yes

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"
Name: "associatemd"; Description: "Associate .md files with Marquis"; GroupDescription: "File associations:"; Flags: checkedonce
Name: "associatemarkdown"; Description: "Associate .markdown files with Marquis"; GroupDescription: "File associations:"; Flags: checkedonce

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Marquis"; Filename: "{app}\marquis.exe"; IconFilename: "{app}\marquis.exe"
Name: "{group}\Uninstall Marquis"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Marquis"; Filename: "{app}\marquis.exe"; Tasks: desktopicon

[Registry]
; .md file association
Root: HKCU; Subkey: "Software\Classes\.md"; ValueType: string; ValueName: ""; ValueData: "Marquis.MarkdownFile"; Flags: uninsdeletevalue; Tasks: associatemd
Root: HKCU; Subkey: "Software\Classes\Marquis.MarkdownFile"; ValueType: string; ValueName: ""; ValueData: "Markdown File"; Flags: uninsdeletekey; Tasks: associatemd
Root: HKCU; Subkey: "Software\Classes\Marquis.MarkdownFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\marquis.exe,1"; Tasks: associatemd
Root: HKCU; Subkey: "Software\Classes\Marquis.MarkdownFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\marquis.exe"" ""%1"""; Tasks: associatemd

; .markdown file association
Root: HKCU; Subkey: "Software\Classes\.markdown"; ValueType: string; ValueName: ""; ValueData: "Marquis.MarkdownFile"; Flags: uninsdeletevalue; Tasks: associatemarkdown
Root: HKCU; Subkey: "Software\Classes\Marquis.MarkdownFile"; ValueType: string; ValueName: ""; ValueData: "Markdown File"; Flags: uninsdeletekey; Tasks: associatemarkdown
Root: HKCU; Subkey: "Software\Classes\Marquis.MarkdownFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\marquis.exe,1"; Tasks: associatemarkdown
Root: HKCU; Subkey: "Software\Classes\Marquis.MarkdownFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\marquis.exe"" ""%1"""; Tasks: associatemarkdown

[Run]
Filename: "{app}\marquis.exe"; Description: "Launch Marquis"; Flags: nowait postinstall skipifsilent
