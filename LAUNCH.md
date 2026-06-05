# 🦆 LAUNCH GUIDE — get Lucky Duck playable (first laptop session)

You only do this ONCE. After it's published, you manage everything from your phone again.
Total time: ~30 minutes. Follow in order. Don't skip.

---

## STEP 0 — on your PHONE first (before the laptop)
Make sure your latest code is pushed:
```
sh ~/go.sh
```
Rainbow duck = good. Now go to the laptop.

---

## STEP 1 — Install Roblox Studio (free)
1. Go to: https://create.roblox.com/landing
2. Click **Start Creating** → it downloads Roblox Studio.
3. Install it, open it, sign in with your Roblox account (same one: curiousstitches).

## STEP 2 — Get your code onto the laptop
Easiest way (no Git needed):
1. Open: https://github.com/curiousstitches/Lucky-Ducky-simulator-1st-Roblox-attempt-
2. Green **Code** button → **Download ZIP**.
3. Unzip it. Remember where it landed (e.g. Downloads/Lucky-Ducky...). You'll see a `src` folder and `default.project.json` inside.

## STEP 3 — Install Rojo (the bridge)
Two parts — both from: https://rojo.space/docs/v7/getting-started/installation/

A) **Rojo Studio plugin:**
   - Open Studio → top menu **Plugins** tab → **Manage Plugins** → or use the **Creator Store / Toolbox**, search **"Rojo"**, install the official one by Roblox-rbx.

B) **Rojo desktop app** (so `rojo serve` works):
   - Simplest: download the **Rojo installer** for Windows/Mac from the install page above. Run it.
   - (If it mentions "Rokit" or "Aftman" — that's an auto-installer that reads the `rokit.toml` in your folder and grabs the exact right version. Either path is fine.)

## STEP 4 — Start the bridge
1. Open the folder you unzipped in **a terminal**:
   - **Windows:** open the folder in File Explorer → click the address bar → type `cmd` → Enter.
   - **Mac:** right-click the folder → "New Terminal at Folder" (or `cd` into it).
2. Type:
```
rojo serve
```
3. It should say it's serving on `localhost:34872`. **Leave this window open.**

## STEP 5 — Connect Studio
1. In Studio: **File → New** → pick **Baseplate**.
2. Find the **Rojo** plugin button (Plugins tab) → click it → **Connect**.
3. Your 53 files pour in. You'll see folders fill up in ServerScriptService, ReplicatedStorage, and StarterPlayer.

## STEP 6 — PLAY 🦆
- Press the big blue **▶ Play** button (top, "Home" tab).
- You spawn in the **Lucky Duck Garage** with a free starter duck.
- Walk into crates → currency climbs. Hit dispensers. Tap the on-screen buttons (Shop, Ducks, Lobby, Menu).
- Press **Stop** (red square) when done testing.

## STEP 7 — Publish so the world can play
1. **File → Publish to Roblox As…**
2. Name it (e.g. "Jeepers-Get-DUCKED"), pick a genre, **Create / Publish**.
3. Open the **Creator Dashboard**: https://create.roblox.com/dashboard/creations
4. Click your game → **⚙ Settings** → set **Playability** to **Public**.
5. Done — your game now has a real link that works on **phones, PC, console**. Share it anywhere.

---

## 🛟 IF SOMETHING GOES WRONG (the only 3 things that ever do)

**"rojo: command not found" (Step 4)** → the desktop app didn't install. Re-run the Rojo installer from the install page, close & reopen the terminal, try `rojo serve` again. Or run `rokit install` in the folder first (reads rokit.toml).

**Rojo plugin won't Connect / "API access" error (Step 5)** → In Studio: **File → Game Settings → Security → turn ON "Allow HTTP Requests" AND "Enable Studio Access to API Services"**. Save. Reconnect. (Our game uses DataStores + HTTP, so both must be ON — this is required to publish anyway.)

**Files connect but nothing happens on Play** → make sure `rojo serve` is still running in the terminal (Step 4) and the plugin says "Connected". Stop, reconnect, Play again.

Anything else: screenshot it, send it to me on your phone, I'll solve it on the spot.
