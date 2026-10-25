; Installateur Windows (Inno Setup). Compilé par la CI :
;   iscc /DAppVersion=1.0.0 installer\windows.iss
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppId={{6F1E3C52-8B7A-4C1D-9E0B-5A2D7F4B9C31}
AppName=Mon stock
AppVersion={#AppVersion}
AppPublisher=Mon stock
; Installation pour l'utilisateur courant : pas besoin d'être administrateur.
PrivilegesRequired=lowest
DefaultDirName={localappdata}\Programs\Mon stock
DefaultGroupName=Mon stock
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\gestion_stock.exe
OutputDir=..\build\installer
OutputBaseFilename=mon-stock-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Mon stock"; Filename: "{app}\gestion_stock.exe"
Name: "{autodesktop}\Mon stock"; Filename: "{app}\gestion_stock.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\gestion_stock.exe"; Description: "{cm:LaunchProgram,Mon stock}"; Flags: nowait postinstall skipifsilent
