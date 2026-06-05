# duckpush.ps1 — unzip newest lucky-duck-dev zip into place, push to GitHub, clean up.
# SUCCESS = rainbow neon ducks + quacks.  FAIL = red text with blue detail lines.

$repo   = "https://github.com/curiousstitches/Jeepers-Get-DUCKED-.git"
$dl     = "$env:USERPROFILE\Downloads"
$dest   = "$env:USERPROFILE\Downloads\lucky-duck-dev\lucky-duck-dev"
$rainbow = @("Red","DarkYellow","Yellow","Green","Cyan","Blue","Magenta")

function Fail($msg, $detail) {
    Write-Host ""
    Write-Host "  XX  PUSH FAILED  XX" -ForegroundColor Red
    Write-Host "  $msg" -ForegroundColor Red
    if ($detail) { Write-Host "  detail: $detail" -ForegroundColor Blue }
    exit 1
}

function Win {
    $ducks = @(
        "        __         __         __     ",
        "      <(o )___   <(o )___   <(o )___  ",
        "       ( ._> /    ( ._> /    ( ._> /  ",
        "        `---'      `---'      `---'   "
    )
    Write-Host ""
    foreach ($line in $ducks) {
        $c = $rainbow[(Get-Random -Max $rainbow.Count)]
        Write-Host $line -ForegroundColor $c
    }
    $quack = "quack.......QUACK!!!!!!!!!QuAcK???????"
    $out = ""
    for ($i=0; $i -lt $quack.Length; $i++) {
        Write-Host -NoNewline $quack[$i] -ForegroundColor $rainbow[$i % $rainbow.Count]
    }
    Write-Host ""
    Write-Host "  YOU'VE BEEN DUCKED! PUSH COMPLETE  " -ForegroundColor Yellow
    Write-Host ""
}

# 1) find newest zip
$zip = Get-ChildItem $dl -Filter "lucky-duck-dev*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $zip) { Fail "No lucky-duck-dev*.zip found in Downloads." "Download the zip first." }

# 2) confirm overwrite
Write-Host "About to unzip '$($zip.Name)' over:" -ForegroundColor Cyan
Write-Host "  $dest" -ForegroundColor Cyan
$ans = Read-Host "Overwrite existing files there? (Y/N)"
if ($ans -notmatch '^[Yy]') { Fail "Cancelled by user." "No changes made." }

# 3) unzip
try { Expand-Archive $zip.FullName $dl -Force }
catch { Fail "Unzip failed." $_.Exception.Message }
if (-not (Test-Path "$dest\default.project.json")) { Fail "Project not found after unzip." $dest }

# 4) push
try {
    Set-Location $dest
    if (-not (Test-Path ".git")) { git init | Out-Null; git branch -M main; git remote add origin $repo }
    git add -A
    git commit -m ("update " + (Get-Date -Format "yyyy-MM-dd HH:mm")) 2>$null | Out-Null
    $push = git push -u origin main 2>&1
    if ($LASTEXITCODE -ne 0) { Fail "git push failed." ($push -join ' ') }
} catch { Fail "Git error." $_.Exception.Message }

# 5) delete zip after confirmed push
$del = Read-Host "Push confirmed. Delete the zip '$($zip.Name)'? (Y/N)"
if ($del -match '^[Yy]') { Remove-Item $zip.FullName -Force; Write-Host "Deleted $($zip.Name)" -ForegroundColor Cyan }

Win
