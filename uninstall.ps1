# pretty-claude-cli uninstaller (Windows PowerShell).
#   powershell -ExecutionPolicy Bypass -File uninstall.ps1 [-Purge]
param([switch]$Purge)
$ErrorActionPreference = 'Stop'

$dest     = Join-Path $HOME '.claude\pretty-claude-cli'
$settings = Join-Path $HOME '.claude\settings.json'

if (Test-Path $settings) {
    try {
        $obj = Get-Content -Raw -Path $settings | ConvertFrom-Json
        if ($obj.PSObject.Properties.Name -contains 'statusLine') {
            $obj.PSObject.Properties.Remove('statusLine')
            $json = $obj | ConvertTo-Json -Depth 32
            [System.IO.File]::WriteAllText($settings, $json, (New-Object System.Text.UTF8Encoding($false)))
            Write-Host "> Removed statusLine from $settings"
        }
    } catch { }
}

if ($Purge) {
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Write-Host "> Purged $dest (including your config)"
} else {
    foreach ($f in @('statusline.py', 'statusline.sh', 'statusline.ps1', 'config.example.ini')) {
        $p = Join-Path $dest $f
        if (Test-Path $p) { Remove-Item -Force $p }
    }
    Write-Host "> Removed program files; kept your config at $dest\config.ini"
    Write-Host "  (run with -Purge to delete everything)"
}
Write-Host "OK. Uninstalled. Restart Claude Code." -ForegroundColor Green
