$ErrorActionPreference = "Stop"

$toolDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolHtml = (Get-ChildItem -LiteralPath $toolDir -Filter "*.html" | Select-Object -First 1).FullName
$serverScript = Join-Path $toolDir "x-post-server.js"
$healthUrl = "http://127.0.0.1:8787/health"
$importApiUrl = "http://127.0.0.1:8787/import-directory?character=healthcheck"
$launcherLog = Join-Path $toolDir "manga-tool-launcher.log"
$bundledNode = "C:\Users\myabe\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"

function Write-LauncherLog {
  param([string]$Message)
  $line = "[{0}] {1}" -f (Get-Date).ToString("s"), $Message
  Add-Content -LiteralPath $launcherLog -Value $line -Encoding UTF8
  Write-Host $Message
}

function Test-XPostServer {
  try {
    $response = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 2
    return $response.StatusCode -eq 200
  } catch {
    return $false
  }
}

function Test-ImportApi {
  try {
    $response = Invoke-WebRequest -UseBasicParsing -Uri $importApiUrl -TimeoutSec 2
    return $response.StatusCode -eq 200
  } catch {
    return $false
  }
}

function Stop-XPostServerOnPort {
  try {
    $connections = Get-NetTCPConnection -LocalPort 8787 -State Listen -ErrorAction SilentlyContinue
    foreach ($connection in $connections) {
      if ($connection.OwningProcess) {
        Stop-Process -Id $connection.OwningProcess -Force -ErrorAction SilentlyContinue
      }
    }
  } catch {
    Write-LauncherLog "Could not stop old server automatically."
  }
}

function Get-NodePath {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if ($node) { return $node.Source }
  if (Test-Path -LiteralPath $bundledNode) { return $bundledNode }
  throw "Node.js was not found."
}

Write-LauncherLog "Starting Umbrella Parade manga tool."

if ((Test-XPostServer) -and (-not (Test-ImportApi))) {
  Write-LauncherLog "Old X post server detected. Restarting..."
  Stop-XPostServerOnPort
  Start-Sleep -Milliseconds 800
}

if (-not (Test-XPostServer)) {
  Write-LauncherLog "Starting X post server..."
  $nodePath = Get-NodePath
  Write-LauncherLog "Node: $nodePath"
  Write-LauncherLog "Server script: $serverScript"
  Start-Process -FilePath $nodePath -ArgumentList @("`"$serverScript`"") -WorkingDirectory $toolDir -WindowStyle Hidden

  for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 500
    if ((Test-XPostServer) -and (Test-ImportApi)) { break }
  }
} else {
  Write-LauncherLog "X post server is already running."
}

if (-not ((Test-XPostServer) -and (Test-ImportApi))) {
  Write-LauncherLog "X post server did not start correctly."
  throw "X post server did not start correctly. See $launcherLog"
}

if ($toolHtml -and (Test-Path -LiteralPath $toolHtml)) {
  Write-LauncherLog "Opening manga tool: $toolHtml"
  Start-Process -FilePath $toolHtml
} else {
  throw "Manga tool HTML was not found."
}
