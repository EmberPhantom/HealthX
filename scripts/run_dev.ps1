# ============================================================
# HealthX — Dev Runner for Physical Device Testing
# Automatically detects your machine's LAN IP and passes it
# to Flutter so the physical device can reach the backend.
# Usage:
#   .\scripts\run_dev.ps1              (run on connected device)
#   .\scripts\run_dev.ps1 -Release    (release mode)
#   .\scripts\run_dev.ps1 -GetIp      (just print the IP)
# ============================================================

param(
  [switch]$Release,
  [switch]$GetIp
)

# ── Detect LAN IP ─────────────────────────────────────────────
# Prefer the Wi-Fi adapter; fall back to any active IPv4
function Get-LanIp {
  $ip = $null

  # Try Wi-Fi first (most common for physical device testing)
  try {
    $wifiIp = Get-NetIPAddress -AddressFamily IPv4 `
      | Where-Object { $_.InterfaceAlias -match 'Wi-Fi|WiFi|WLAN|Wireless' `
                    -and $_.IPAddress -notmatch '^169\.' `
                    -and $_.IPAddress -ne '127.0.0.1' } `
      | Select-Object -First 1 -ExpandProperty IPAddress
    if ($wifiIp) { return $wifiIp }
  } catch {}

  # Fall back to any active non-loopback IPv4
  try {
    $anyIp = Get-NetIPAddress -AddressFamily IPv4 `
      | Where-Object { $_.IPAddress -notmatch '^(127\.|169\.)' } `
      | Sort-Object PrefixLength `
      | Select-Object -First 1 -ExpandProperty IPAddress
    if ($anyIp) { return $anyIp }
  } catch {}

  # Last resort: use ipconfig parsing
  $ipconfigOut = ipconfig | Select-String 'IPv4'
  foreach ($line in $ipconfigOut) {
    $match = $line -match '(\d+\.\d+\.\d+\.\d+)'
    if ($match -and $Matches[1] -ne '127.0.0.1' -and !($Matches[1].StartsWith('169.'))) {
      return $Matches[1]
    }
  }

  return $null
}

$devHost = Get-LanIp

if (-not $devHost) {
  Write-Host "❌ Could not detect a LAN IP address. Are you connected to Wi-Fi?" -ForegroundColor Red
  exit 1
}

Write-Host "✅ Detected LAN IP: $devHost" -ForegroundColor Cyan
Write-Host "📡 Backend URL will be: http://${devHost}:3000" -ForegroundColor Green

# ── Check if Backend is running ────────────────────────────────
$backendRunning = netstat -ano | findstr ":3000" | findstr "LISTENING"
if (-not $backendRunning) {
  Write-Host ""
  Write-Host "⚠️  WARNING: Backend does not appear to be running on port 3000!" -ForegroundColor Yellow
  Write-Host "   Make sure to run 'npm run dev' in another terminal." -ForegroundColor Gray
  Write-Host ""
}

if ($GetIp) { exit 0 }

# ── Navigate to Flutter project ────────────────────────────────
$flutterDir = Join-Path $PSScriptRoot "..\frontend\HealthX"
Set-Location $flutterDir

# ── Build flutter run command ──────────────────────────────────
$dartDefines = "--dart-define=DEV_HOST=$devHost"
$mode = if ($Release) { "--release" } else { "--debug" }

Write-Host ""
Write-Host "🚀 Launching Flutter ($mode)..." -ForegroundColor Magenta
Write-Host "   flutter run $mode $dartDefines"
Write-Host ""

flutter run $mode $dartDefines
