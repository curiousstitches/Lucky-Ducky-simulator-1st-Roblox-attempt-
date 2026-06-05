# GO.ps1 — ALL-IN-ONE: update from newest zip -> push to GitHub -> start Rojo.
# Just run this one file every time. It auto-finds the newest lucky-duck-dev zip in Downloads.
$ErrorActionPreference = "Continue"
$dl   = "$env:USERPROFILE\Downloads"
$proj = "$dl\lucky-duck-dev\lucky-duck-dev"
if (-not (Test-Path $proj)) { $proj = "$dl\lucky-duck-dev" }
$repo = "https://github.com/curiousstitches/Jeepers-Get-DUCKED-.git"
$rojo = "$env:USERPROFILE\Downloads\rojo\rojo.exe"

# ---------- STEP 1: UPDATE FROM NEWEST ZIP ----------
Write-Host "`n[1/3] Updating from newest zip..." -ForegroundColor Cyan
# grab the newest .zip of ANY name in Downloads (handles files.zip, lucky-duck-dev.zip, etc.)
$zip = Get-ChildItem $dl -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($zip) {
  Remove-Item "$dl\_tmp" -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive $zip.FullName "$dl\_tmp" -Force
  if (-not (Test-Path $proj)) { New-Item -ItemType Directory -Path $proj | Out-Null }
  # the project folder may be at _tmp\ or _tmp\lucky-duck-dev\ — find default.project.json
  $src = Get-ChildItem "$dl\_tmp" -Recurse -Filter default.project.json | Select-Object -First 1
  if ($src) {
    Copy-Item "$($src.DirectoryName)\*" $proj -Recurse -Force
    Write-Host "    Updated from $($zip.Name)" -ForegroundColor Green
  } else {
    Write-Host "    Zip had no default.project.json - skipped." -ForegroundColor Yellow
  }
  Remove-Item "$dl\_tmp" -Recurse -Force -ErrorAction SilentlyContinue
} else {
  Write-Host "    No zip found - using existing files." -ForegroundColor Yellow
}

# ---------- STEP 2: PUSH TO GITHUB ----------
Write-Host "`n[2/3] Pushing to GitHub..." -ForegroundColor Cyan
Set-Location $proj
if (-not (Test-Path ".git")) { git init | Out-Null; git branch -M main }
git remote remove origin 2>$null
git remote add origin $repo
git add -A
git commit -m ("update " + (Get-Date -Format "yyyy-MM-dd HH:mm")) 2>$null
git push -u origin main --force
Write-Host "    Push attempted (see above)." -ForegroundColor Green

# ---------- STEP 3: START ROJO (stays open) ----------
Write-Host "`n[3/3] Starting Rojo... leave this window OPEN." -ForegroundColor Cyan
if (-not (Test-Path $rojo)) {
  Write-Host "    Rojo not found - installing..." -ForegroundColor Yellow
  irm https://github.com/rojo-rbx/rojo/releases/download/v7.5.1/rojo-7.5.1-windows-x86_64.zip -OutFile "$dl\rojo.zip"
  Expand-Archive "$dl\rojo.zip" "$env:USERPROFILE\Downloads\rojo" -Force
}
Write-Host "`n  In Studio now: Rojo plugin -> Connect -> Play  `n" -ForegroundColor Yellow
& $rojo serve "$proj\default.project.json"
