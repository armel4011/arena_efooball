; ─────────────────────────────────────────────────────────────────────
; ARENA Admin Desktop — Installeur Windows (Inno Setup 6)
; ─────────────────────────────────────────────────────────────────────
; UN SEUL FICHIER d'installation : embarque toute l'app (Release),
; crée les raccourcis Menu Démarrer + Bureau, gère la désinstallation.
; Aucun certificat à installer (contrairement au MSIX).
;
; Compilation (après un build release de l'app) :
;   flutter build windows -t lib/main_admin_desktop.dart
;   "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" windows\installer\arena_admin_installer.iss
;
; → Résultat : dist\arena-admin-installeur-<version>.exe
; ─────────────────────────────────────────────────────────────────────

#define AppName "ARENA Admin"
#define AppVersion "1.0.2"
#define AppPublisher "Arena"
#define AppExeName "arena.exe"
; Chemins relatifs à ce fichier .iss (windows/installer/)
#define ReleaseDir "..\..\build\windows\x64\runner\Release"
#define OutputDir "..\..\dist"

[Setup]
AppId={{8F3E6A2D-4B7C-4E9A-AF21-ARENA0ADMIN01}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://github.com/armel4011/arena_efooball
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
OutputDir={#OutputDir}
OutputBaseFilename=arena-admin-installeur-{#AppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Installation PAR UTILISATEUR (AppData\Local\Programs) : aucun droit
; admin / UAC requis. L'utilisateur peut forcer Program Files via le
; dialogue si besoin (PrivilegesRequiredOverridesAllowed).
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; L'app est 64 bits uniquement.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; \
  GroupDescription: "Raccourcis supplémentaires :"

[Files]
; Toute l'app Release. Exclusions :
;  * .sentry-native : artefacts runtime créés quand l'app dev tourne
;    depuis ce dossier (verrous + données de crash locales).
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; \
  Excludes: ".sentry-native\*,.sentry-native"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Désinstaller {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; \
  Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Lancer {#AppName} maintenant"; \
  Flags: nowait postinstall skipifsilent
