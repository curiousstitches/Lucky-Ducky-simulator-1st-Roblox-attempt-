# 🦆 LAUNCH KIT — what each file does

Put this whole folder anywhere easy (like Downloads). To run any script:
**Right-click it → "Run with PowerShell"**, OR paste the line shown under it into a PowerShell window.

---

## ▶ 1-rojo-start.ps1   — START THE GAME (use this every time)
Starts the Rojo server that feeds your files into Roblox Studio.
1. Run it. (If Rojo isn't installed, it auto-installs.)
2. Leave the window OPEN.
3. In Studio: click the **Rojo** plugin → **Connect** → press **▶ Play**.

Run line:
```
powershell -ExecutionPolicy Bypass -File ".\1-rojo-start.ps1"
```

---

## ⬇ 2-update-from-zip.ps1   — LOAD A NEW VERSION
Whenever Claude gives you a new `lucky-duck-dev` zip, download it to Downloads, then run this.
It unzips the newest one into your project folder. After it finishes, re-Connect Rojo in Studio.

Run line:
```
powershell -ExecutionPolicy Bypass -File ".\2-update-from-zip.ps1"
```

---

## ⬆ 3-push-to-github.ps1   — BACK UP TO GITHUB
Saves your project up to your GitHub repo (Jeepers-Get-DUCKED-). Optional — only for backup.
First time, a GitHub sign-in window pops up; log in as **curiousstitches**.

Run line:
```
powershell -ExecutionPolicy Bypass -File ".\3-push-to-github.ps1"
```

---

## TYPICAL FLOW
- **Just want to play?** → run **1-rojo-start**, then Connect + Play in Studio.
- **Got a new zip from Claude?** → run **2-update-from-zip**, then re-Connect + Play.
- **Want a backup online?** → run **3-push-to-github**.

## IF STUDIO SAYS "HTTP requests can only be executed..." or won't connect
In Studio: **File → Game Settings → Security** → turn ON **Allow HTTP Requests** AND
**Enable Studio Access to API Services** → Save. Then Connect again.
(If a popup asks to allow the Rojo plugin's HTTP, click Allow.)

## NOTE ON SAVING
Until you **Publish** the game (File → Publish to Roblox As…) and enable API access,
the game runs in MEMORY MODE — you can play and test, but progress won't save between sessions.
That's normal and expected before launch.
