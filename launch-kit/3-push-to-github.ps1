# 3-push-to-github.ps1 — saves your project up to GitHub (backup). Asks GitHub sign-in first time.
$proj = "$env:USERPROFILE\Downloads\lucky-duck-dev\lucky-duck-dev"
if (-not (Test-Path "$proj\default.project.json")) { $proj = "$env:USERPROFILE\Downloads\lucky-duck-dev" }
$repo = "https://github.com/curiousstitches/Jeepers-Get-DUCKED-.git"

Set-Location $proj
if (-not (Test-Path ".git")) { git init; git branch -M main }
git remote remove origin 2>$null
git remote add origin $repo
git add -A
git commit -m ("update " + (Get-Date -Format "yyyy-MM-dd HH:mm"))
git push -u origin main --force
Write-Host "`n  PUSHED to GitHub  " -ForegroundColor Green
