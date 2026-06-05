# push.ps1 — push the game folder to GitHub from Windows
# Usage: right-click -> Run with PowerShell, OR in PowerShell:  ./push.ps1
$ErrorActionPreference = "Stop"
$repo = "https://github.com/curiousstitches/Jeepers-Get-DUCKED-.git"
$folder = "C:\Users\thego\Downloads\lucky-duck-dev\lucky-duck-dev"

Set-Location $folder
Write-Host "Pushing from $folder" -ForegroundColor Cyan

if (-not (Test-Path ".git")) { git init; git branch -M main; git remote add origin $repo }
git add -A
$msg = "update " + (Get-Date -Format "yyyy-MM-dd HH:mm")
git commit -m $msg
git push -u origin main

Write-Host "DONE - pushed to GitHub" -ForegroundColor Green
