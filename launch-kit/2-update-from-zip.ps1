# 2-update-from-zip.ps1 — unzips the newest lucky-duck-dev download into your project folder.
# Use this whenever Claude gives you a new zip. Then re-Connect Rojo in Studio.
$dl   = "$env:USERPROFILE\Downloads"
$proj = "$dl\lucky-duck-dev\lucky-duck-dev"
if (-not (Test-Path $proj)) { $proj = "$dl\lucky-duck-dev" }

$zip = Get-ChildItem $dl -Filter "lucky-duck-dev*" |
  Where-Object { $_.Extension -eq ".zip" -or $_.Name -notlike "*.*" } |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $zip) { Write-Host "No lucky-duck-dev zip found in Downloads." -ForegroundColor Red; exit 1 }

Write-Host "Updating from $($zip.Name)..." -ForegroundColor Cyan
Remove-Item "$dl\_tmp" -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive $zip.FullName "$dl\_tmp" -Force
Copy-Item "$dl\_tmp\lucky-duck-dev\*" $proj -Recurse -Force
Remove-Item "$dl\_tmp" -Recurse -Force
Write-Host "DONE - files updated at $proj" -ForegroundColor Green
Write-Host "Now: re-Connect Rojo in Studio and press Play." -ForegroundColor Green
