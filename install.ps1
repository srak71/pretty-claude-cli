# pretty-claude-cli installer (Windows PowerShell).
#   Run from the repo folder:  powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = 'Stop'

$srcDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest     = Join-Path $HOME '.claude\pretty-claude-cli'
$settings = Join-Path $HOME '.claude\settings.json'

# Verify Python is available (required at runtime).
$hasPy = @('python', 'py', 'python3') | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue }
if (-not $hasPy) {
    Write-Host 'ERROR: Python 3 is required but was not found on PATH.' -ForegroundColor Red
    Write-Host '  Install it from https://www.python.org/downloads/ (tick "Add to PATH").'
    exit 1
}

Write-Host "> Installing pretty-claude-cli -> $dest"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
foreach ($f in @('statusline.py', 'statusline.sh', 'statusline.ps1', 'config.example.ini')) {
    Copy-Item -Force (Join-Path $srcDir $f) (Join-Path $dest $f)
}

$configPath = Join-Path $dest 'config.ini'
if (Test-Path $configPath) {
    Write-Host "> Keeping your existing config: $configPath"
} else {
    Copy-Item -Force (Join-Path $srcDir 'config.example.ini') $configPath
    Write-Host "> Wrote starter config: $configPath"
}

# Build the command with forward slashes (Git Bash eats backslashes) and quote
# the path so it survives home directories that contain spaces.
$ps1Path = ((Join-Path $dest 'statusline.ps1') -replace '\\', '/')
$command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$ps1Path`""

# Patch settings.json, preserving any existing keys.
New-Item -ItemType Directory -Force -Path (Split-Path $settings) | Out-Null
if (Test-Path $settings) {
    try { $obj = Get-Content -Raw -Path $settings | ConvertFrom-Json } catch { $obj = [pscustomobject]@{} }
} else {
    $obj = [pscustomobject]@{}
}
$statusLine = [pscustomobject]@{ type = 'command'; command = $command; refreshInterval = 1 }
if ($obj.PSObject.Properties.Name -contains 'statusLine') {
    $obj.statusLine = $statusLine
} else {
    $obj | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue $statusLine
}
# Write UTF-8 WITHOUT BOM (Windows PowerShell 5.1's -Encoding UTF8 adds a BOM
# that some JSON parsers reject).
$json = $obj | ConvertTo-Json -Depth 32
[System.IO.File]::WriteAllText($settings, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "> statusLine configured in $settings (refreshInterval=1)"

Write-Host "OK. Start a new Claude Code session to see it." -ForegroundColor Green
Write-Host "   Customize colors / emojis:  $configPath"
