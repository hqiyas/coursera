param(
    [Parameter(Mandatory = $false)]
    [string]$TargetGroup = "",

    [Parameter(Mandatory = $false)]
    [string]$AgentExecutablePath = "C:\Program Files\xSecuritas\Agent\xsecuritas-watermark.exe",

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "C:\ProgramData\xSecuritas\Watermark\watermark.json",

    [Parameter(Mandatory = $false)]
    [string]$ProcessName = "xsecuritas-watermark"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-UserInGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupName
    )

    if ([string]::IsNullOrWhiteSpace($GroupName)) {
        return $true
    }

    try {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        foreach ($groupSid in $identity.Groups) {
            try {
                $groupAsName = $groupSid.Translate([System.Security.Principal.NTAccount]).Value
                if ($groupAsName.Equals($GroupName, [System.StringComparison]::OrdinalIgnoreCase)) {
                    return $true
                }
            } catch {
                continue
            }
        }
    } catch {
        return $false
    }

    return $false
}

if (-not (Test-Path -LiteralPath $AgentExecutablePath)) {
    return
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    return
}

if (-not (Test-UserInGroup -GroupName $TargetGroup)) {
    try {
        Get-Process -Name $ProcessName -ErrorAction Stop | Stop-Process -Force -ErrorAction SilentlyContinue
    } catch {
        # No running process for this user session.
    }
    return
}

try {
    $alreadyRunning = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($null -ne $alreadyRunning) {
        return
    }
} catch {
    # Ignore lookup failures and continue attempting to start.
}

Start-Process -FilePath $AgentExecutablePath -ArgumentList @("--config", $ConfigPath) -WindowStyle Hidden
