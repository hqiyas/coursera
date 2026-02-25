param(
    [Parameter(Mandatory = $false)]
    [string]$RunValueName = "xSecuritasWatermark",

    [Parameter(Mandatory = $false)]
    [string]$LocalConfigRoot = "C:\ProgramData\xSecuritas\Watermark",

    [Parameter(Mandatory = $false)]
    [string]$ProcessName = "xsecuritas-watermark"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    throw "Run this uninstall script in an elevated PowerShell session."
}

$runRegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
Remove-ItemProperty -Path $runRegistryPath -Name $RunValueName -ErrorAction SilentlyContinue

try {
    Get-Process -Name $ProcessName -ErrorAction Stop | Stop-Process -Force -ErrorAction SilentlyContinue
} catch {
    # Process not running in this session.
}

if (Test-Path -LiteralPath $LocalConfigRoot) {
    Remove-Item -LiteralPath $LocalConfigRoot -Recurse -Force
}

Write-Host "xSecuritas watermark package settings removed."
Write-Host "Note: uninstall the xSecuritas agent separately if required."
