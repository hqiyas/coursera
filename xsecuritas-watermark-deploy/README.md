# xSecuritas Enterprise Screen Watermark - Ready-to-Install Package

This package is prepared for Windows 10/11 domain-joined devices and AD/GPO deployment.

## Included files

- `config/watermark.json`  
  Transparent background + soft semi-transparent tiled diagonal text template.
- `scripts/Install-XSecuritasWatermark.ps1`  
  Installs xSecuritas agent silently, copies config, and sets user-logon autostart.
- `scripts/Start-XSecuritasWatermark.ps1`  
  Runs at user logon, checks AD group membership, and starts overlay only for targeted users.
- `scripts/Uninstall-XSecuritasWatermark.ps1`  
  Removes autostart and local package files.
- `packaging/xsecuritas-watermark-bootstrap.wxs`  
  WiX source to build a single deployable MSI bootstrap package.
- `packaging/build-msi.sh`  
  Linux build script that compiles the MSI using `wixl`.

## Build a single MSI (from this repo)

Run:

```bash
chmod +x ./packaging/build-msi.sh
./packaging/build-msi.sh
```

Output:

- `../dist/xsecuritas-watermark-bootstrap.msi`

The MSI installs:

- `C:\ProgramData\xSecuritas\Watermark\watermark.json`
- `C:\ProgramData\xSecuritas\Watermark\Start-XSecuritasWatermark.ps1`
- `C:\ProgramData\xSecuritas\Watermark\Uninstall-XSecuritasWatermark.ps1`
- `HKLM\Software\Microsoft\Windows\CurrentVersion\Run\xSecuritasWatermark`

Install command (silent):

```powershell
msiexec /i xsecuritas-watermark-bootstrap.msi /qn TARGETGROUP="CONTOSO\GG_XSecuritas_Watermark_Users"
```

Optional property override for a non-default agent path:

```powershell
msiexec /i xsecuritas-watermark-bootstrap.msi /qn TARGETGROUP="CONTOSO\GG_XSecuritas_Watermark_Users" AGENTEXEPATH="D:\Apps\xSecuritas\Agent\xsecuritas-watermark.exe"
```

Note: This MSI deploys watermark configuration and logon autostart. It assumes the xSecuritas agent binary is installed separately (machine GPO/software deployment).

## Quick install (single endpoint)

1. Copy this folder and your xSecuritas installer (`.msi` or `.exe`) to a local path.
2. Run elevated PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\scripts\Install-XSecuritasWatermark.ps1 `
  -InstallerPath "C:\Install\xSecuritasAgent.msi" `
  -TargetGroup "CONTOSO\GG_XSecuritas_Watermark_Users"
```

3. Sign out/in (or run `scripts\Start-XSecuritasWatermark.ps1`) to validate overlay startup.

## GPO deployment (recommended)

## 1) Stage files

Copy package and installer to SYSVOL, for example:

- `\\contoso.com\SYSVOL\contoso.com\scripts\xsecuritas-watermark-deploy\`
- `\\contoso.com\SYSVOL\contoso.com\software\xSecuritasAgent.msi`

## 2) Create AD security group

Create and populate:

- `CONTOSO\GG_XSecuritas_Watermark_Users`

Only members of this group will see the watermark.

## 3) Computer startup script GPO

Link to workstation OU and run as startup script:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "\\contoso.com\SYSVOL\contoso.com\scripts\xsecuritas-watermark-deploy\scripts\Install-XSecuritasWatermark.ps1" -InstallerPath "\\contoso.com\SYSVOL\contoso.com\software\xSecuritasAgent.msi" -TargetGroup "CONTOSO\GG_XSecuritas_Watermark_Users"
```

This performs:

- silent agent installation
- local config copy (`C:\ProgramData\xSecuritas\Watermark\watermark.json`)
- autostart registration in `HKLM\Software\Microsoft\Windows\CurrentVersion\Run`

## 4) Configuration updates later

Edit `config\watermark.json` in SYSVOL and rerun install script via startup script.
The script overwrites local config each run.

## Usability settings in the provided template

- Fully transparent background: `backgroundColor = #00000000`
- Semi-transparent text: `textColor = #40444444`
- Diagonal tiled text: `angleDegrees = 35`
- Refresh every 60 seconds
- Intended click-through behavior controlled by `interaction` section

## Click-through and transparency verification checklist

1. Move cursor over watermark text and click underlying UI elements.
2. Drag-select text/files through watermark text area.
3. Scroll and right-click through watermark text area.
4. Confirm no taskbar icon and no focus stealing by overlay.
5. Validate no tinted panel behind text (only glyphs visible).

## Rollback

Run elevated:

```powershell
.\scripts\Uninstall-XSecuritasWatermark.ps1
```

Then uninstall the xSecuritas agent product if required by your software inventory policy.
