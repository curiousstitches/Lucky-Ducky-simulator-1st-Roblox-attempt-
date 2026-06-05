# 1-rojo-start.ps1 — starts the Rojo server so Studio can sync your files.
# Run this, leave the window OPEN, then in Studio: Rojo plugin -> Connect -> Play.
$rojo = "$env:USERPROFILE\Downloads\rojo\rojo.exe"
$proj = "$env:USERPROFILE\Downloads\lucky-duck-dev\lucky-duck-dev\default.project.json"
if (-not (Test-Path $proj)) { $proj = "$env:USERPROFILE\Downloads\lucky-duck-dev\default.project.json" }
if (-not (Test-Path $rojo)) {
  Write-Host "Rojo app not found. Installing..." -ForegroundColor Yellow
  irm https://github.com/rojo-rbx/rojo/releases/download/v7.5.1/rojo-7.5.1-windows-x86_64.zip -OutFile "$env:USERPROFILE\Downloads\rojo.zip"
  Expand-Archive "$env:USERPROFILE\Downloads\rojo.zip" "$env:USERPROFILE\Downloads\rojo" -Force
}
Write-Host "Serving: $proj" -ForegroundColor Cyan
Write-Host "Leave this window open. In Studio: Rojo -> Connect -> Play." -ForegroundColor Green
& $rojo serve $proj
