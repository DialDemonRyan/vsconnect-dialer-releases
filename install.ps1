# install.ps1 — One-shot installer for VS Connect Dialer on Windows.
# Paste this in PowerShell:
#   irm https://raw.githubusercontent.com/DialDemonRyan/vsconnect-dialer-releases/main/install.ps1 | iex
#
# Downloads the latest Windows build, drops it in a stable folder, makes a
# Desktop + Start Menu shortcut, and launches it.

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "VS Connect Dialer - Installer" -ForegroundColor Cyan
Write-Host "==============================================="
Write-Host ""

# Find the latest Windows .exe from the GitHub releases API
Write-Host "> Finding latest release..."
$rel = Invoke-RestMethod -Uri "https://api.github.com/repos/DialDemonRyan/vsconnect-dialer-releases/releases/latest" -Headers @{ "User-Agent" = "vsc-installer" }
$asset = $rel.assets | Where-Object { $_.name -like "*windows.exe" } | Select-Object -First 1
if (-not $asset) {
  Write-Host "x Couldn't find a Windows build in the latest release." -ForegroundColor Red
  Write-Host "  Download manually: https://github.com/DialDemonRyan/vsconnect-dialer-releases/releases/latest"
  return
}
$url = $asset.browser_download_url
Write-Host "  -> $url"

# Install location: %LOCALAPPDATA%\VS Connect Dialer
$dir = Join-Path $env:LOCALAPPDATA "VS Connect Dialer"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$exe = Join-Path $dir "VS Connect Dialer.exe"

# Close any running copy so we can overwrite
Get-Process -Name "VS Connect Dialer" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

Write-Host "> Downloading..."
Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing

# Unblock the file so SmartScreen doesn't hard-block it (still may warn once)
Unblock-File -Path $exe -ErrorAction SilentlyContinue

# Desktop + Start Menu shortcuts
Write-Host "> Creating shortcuts..."
$wsh = New-Object -ComObject WScript.Shell
foreach ($loc in @(
  (Join-Path ([Environment]::GetFolderPath("Desktop")) "VS Connect Dialer.lnk"),
  (Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs\VS Connect Dialer.lnk")
)) {
  try {
    New-Item -ItemType Directory -Force -Path (Split-Path $loc) | Out-Null
    $sc = $wsh.CreateShortcut($loc)
    $sc.TargetPath = $exe
    $sc.WorkingDirectory = $dir
    $sc.Save()
  } catch {}
}

Write-Host ""
Write-Host "> Launching..." -ForegroundColor Green
Start-Process $exe

Write-Host ""
Write-Host "==============================================="
Write-Host "DONE. Next steps:" -ForegroundColor Green
Write-Host ""
Write-Host "  If Windows shows 'Windows protected your PC':"
Write-Host "    click 'More info' -> 'Run anyway' (the app isn't code-signed yet)."
Write-Host ""
Write-Host "  1. Sign up for the two AI services (free credit):"
Write-Host "     - Deepgram (transcription):  https://console.deepgram.com"
Write-Host "     - Anthropic (analysis):      https://console.anthropic.com"
Write-Host "  2. Paste both keys in Settings -> Transcription / Analysis."
Write-Host "  3. Make sure VS Connect (the softphone) is installed."
Write-Host ""
Write-Host "  In Settings -> Dialing, set the URL scheme to 'callto:' if tel: opens the wrong app."
Write-Host "==============================================="
