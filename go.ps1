# go.ps1 — unzip newest lucky-duck-dev.zip into place AND push to GitHub (Windows = your go.sh)
$ErrorActionPreference = "Stop"
$dl   = "$env:USERPROFILE\Downloads"
$dest = "$env:USERPROFILE\Downloads\lucky-duck-dev\lucky-duck-dev"
$repo = "https://github.com/curiousstitches/Jeepers-Get-DUCKED-.git"

# 1) unzip the newest lucky-duck-dev zip over the project folder
$zip = Get-ChildItem $dl -Filter "lucky-duck-dev*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($zip) {
  Write-Host "Unzipping $($zip.Name)..." -ForegroundColor Cyan
  Expand-Archive $zip.FullName "$env:USERPROFILE\Downloads" -Force
}

# 2) push to GitHub
Set-Location $dest
if (-not (Test-Path ".git")) { git init; git branch -M main; git remote add origin $repo }
git add -A
git commit -m ("update " + (Get-Date -Format "yyyy-MM-dd HH:mm")) 2>$null
git push -u origin main

Write-Host "`n  YOU'VE BEEN DUCKED! PUSH COMPLETE  " -ForegroundColor Yellow
