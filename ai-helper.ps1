# AI Terminal Assistant using GitHub Copilot CLI

$script:AI_SESSION_DIR = Join-Path $HOME ".config/gh-copilot/sessions"
$script:AI_CURRENT_SESSION = Join-Path $script:AI_SESSION_DIR "current_session_id"
New-Item -ItemType Directory -Path $script:AI_SESSION_DIR -Force | Out-Null

function _ai_new_uuid {
    $uuidPath = "/proc/sys/kernel/random/uuid"
    if (Test-Path $uuidPath) {
        return (Get-Content -Raw $uuidPath).Trim()
    }

    return [guid]::NewGuid().ToString()
}

function _ai_get_session {
    if (Test-Path $script:AI_CURRENT_SESSION) {
        return (Get-Content -Raw $script:AI_CURRENT_SESSION).Trim()
    }
    return ""
}

function _ai_get_copilot_cmd {
    $cmd = Get-Command copilot -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Path }

    $cmd = Get-Command copilot.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Path }

    return $null
}

function _ai_shell_is_safe {
    param([string]$q)

    if ($q -match "(^|\s)(sudo|su|shutdown|reboot|mkfs|fdisk|eval|exec)(\s|$)") { return $false }
    if ($q -match "(^|\s)rm(\s+.*)?-r(f)?(\s|$)") { return $false }
    if ($q -match "(^|\s)rm(\s+.*)?-rf(\s|$)") { return $false }
    if ($q.Contains(";") -or $q.Contains("&&") -or $q.Contains("||") -or $q.Contains('`') -or $q.Contains('$(')) { return $false }

    return $true
}

function ai {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    if ($Args.Count -eq 0) {
        Write-Host "Usage: ai <query>"
        return 1
    }

    $first = $Args[0]
    if ($first -in @("clear", "reset", "new")) {
        Remove-Item -Force -ErrorAction SilentlyContinue $script:AI_CURRENT_SESSION
        Write-Host "AI session cleared."
        return 0
    }

    if ($first -in @("help", "--help", "-h")) {
        @"
Usage:
  ai <query>        Contextual mode (resume session)
  ai ! <query>      Fast stateless mode (no resume)
  ai clear          Reset session
"@ | Write-Host
        return 0
    }

    $copilotCmd = _ai_get_copilot_cmd
    if (-not $copilotCmd) {
        Write-Host "Error: Copilot CLI not found"
        return 1
    }

    $stateless = $false
    $queryParts = $Args
    if ($Args[0] -eq "!") {
        $stateless = $true
        if ($Args.Count -lt 2) {
            Write-Host "Usage: ai ! <query>"
            return 1
        }
        $queryParts = $Args[1..($Args.Count - 1)]
    }
    $query = ($queryParts -join " ")

    $sessionId = _ai_get_session
    if (-not $stateless -and [string]::IsNullOrWhiteSpace($sessionId)) {
        $sessionId = _ai_new_uuid
        Set-Content -NoNewline -Path $script:AI_CURRENT_SESSION -Value $sessionId
    }

    if ($query -like "*shell command*" -or $query -like "*run *" -or $query -like "*execute *") {
        if (-not (_ai_shell_is_safe $query)) {
            Write-Host "Blocked potentially unsafe shell request."
            return 1
        }
    }

    if ($stateless) {
        & $copilotCmd -p $query --model gpt-5-mini --effort low --allow-all-tools --no-ask-user --silent
    } else {
        & $copilotCmd -p $query --model gpt-5-mini --effort low --resume $sessionId --allow-all-tools --no-ask-user --silent
    }
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Remove-Item -Force -ErrorAction SilentlyContinue $script:AI_CURRENT_SESSION
    }

    return $exitCode
}

$marker = Join-Path $script:AI_SESSION_DIR ".session_marker_$PID"
if (-not (Test-Path $marker)) {
    Remove-Item -Force -ErrorAction SilentlyContinue $script:AI_CURRENT_SESSION
    New-Item -ItemType File -Path $marker -Force | Out-Null
    Get-ChildItem -Path $script:AI_SESSION_DIR -Filter ".session_marker_*" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
