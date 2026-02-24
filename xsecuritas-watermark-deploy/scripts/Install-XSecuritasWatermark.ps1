param(
    [Parameter(Mandatory = $true)]
    [string]$InstallerPath,

    [Parameter(Mandatory = $false)]
    [string]$TargetGroup = "CONTOSO\\GG_XSecuritas_Watermark_Users",

    [Parameter(Mandatory = $false)]
    [string]$AgentExecutablePath = "C:\Program Files\xSecuritas\Agent\xsecuritas-watermark.exe",

    [Parameter(Mandatory = $false)]
    [string]$LocalConfigRoot = "C:\ProgramData\xSecuritas\Watermark",

    [Parameter(Mandatory = $false)]
    [string]$ConfigSourcePath = "",

    [Parameter(Mandatory = $false)]
    [string]$RunValueName = "xSecuritasWatermark"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Agent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Installer file not found: $Path"
    }

    $extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()

    switch ($extension) {
        ".msi" {
            $arguments = @("/i", "`"$Path`"", "/qn", "/norestart")
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru
            if ($process.ExitCode -ne 0) {
                throw "MSI installation failed with exit code $($process.ExitCode)."
            }
        }
        ".exe" {
            $arguments = @("/quiet", "/norestart")
            $process = Start-Process -FilePath $Path -ArgumentList $arguments -Wait -PassThru
            if ($process.ExitCode -ne 0) {
                throw "EXE installation failed with exit code $($process.ExitCode)."
            }
        }
        default {
            throw "Unsupported installer extension '$extension'. Use .msi or .exe."
        }
    }
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

if (-not (Test-IsAdministrator)) {
    throw "Run this installer script in an elevated PowerShell session."
}

$packageRoot = Split-Path -Path $PSScriptRoot -Parent
$defaultConfigSource = Join-Path -Path $packageRoot -ChildPath "config\watermark.json"
$launcherSource = Join-Path -Path $PSScriptRoot -ChildPath "Start-XSecuritasWatermark.ps1"

if ([string]::IsNullOrWhiteSpace($ConfigSourcePath)) {
    $ConfigSourcePath = $defaultConfigSource
}

if (-not (Test-Path -LiteralPath $ConfigSourcePath)) {
    throw "Watermark config not found: $ConfigSourcePath"
}

if (-not (Test-Path -LiteralPath $launcherSource)) {
    throw "Launcher script not found: $launcherSource"
}

Install-Agent -Path $InstallerPath

Ensure-Directory -Path $LocalConfigRoot

$configDestination = Join-Path -Path $LocalConfigRoot -ChildPath "watermark.json"
$launcherDestination = Join-Path -Path $LocalConfigRoot -ChildPath "Start-XSecuritasWatermark.ps1"

Copy-Item -LiteralPath $ConfigSourcePath -Destination $configDestination -Force
Copy-Item -LiteralPath $launcherSource -Destination $launcherDestination -Force

$runCommand = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcherDestination`" -TargetGroup `"$TargetGroup`" -AgentExecutablePath `"$AgentExecutablePath`" -ConfigPath `"$configDestination`""
$runRegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
New-ItemProperty -Path $runRegistryPath -Name $RunValueName -PropertyType String -Value $runCommand -Force | Out-Null

# Start once for the current session so admins can validate immediately after install.
Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoProfile",
    "-WindowStyle", "Hidden",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$launcherDestination`"",
    "-TargetGroup", "`"$TargetGroup`"",
    "-AgentExecutablePath", "`"$AgentExecutablePath`"",
    "-ConfigPath", "`"$configDestination`""
) -WindowStyle Hidden

Write-Host "xSecuritas watermark package installed successfully."
Write-Host "Config: $configDestination"
Write-Host "Launcher: $launcherDestination"
Write-Host "Autostart: HKLM Run -> $RunValueName"
