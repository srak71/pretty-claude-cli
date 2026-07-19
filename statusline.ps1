# pretty-claude-cli launcher (Windows PowerShell).
# Claude Code invokes this via:  powershell -NoProfile -File statusline.ps1
# It locates Python and pipes the session JSON (stdin) to statusline.py.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = Join-Path $here 'statusline.py'

# Collect the JSON that Claude Code piped to stdin.
$payload = $input | Out-String

# Find a Python launcher (python, then the py launcher, then python3).
$py = $null
$pyArgs = @()
foreach ($cand in @('python', 'py', 'python3')) {
    if (Get-Command $cand -ErrorAction SilentlyContinue) {
        $py = $cand
        if ($cand -eq 'py') { $pyArgs = @('-3') }
        break
    }
}

if (-not $py) {
    Write-Output 'pretty-claude-cli: python 3 not found on PATH'
    exit 0
}

$payload | & $py @pyArgs $script
