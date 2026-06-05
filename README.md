# 🦆 Jeepers-Get-DUCKED

A Roblox rubber-duck collection simulator. Hatch ducks, smash everything, climb 100 stages,
rebirth for power, and chase millions of procedurally-generated ducks.
Tagline: **Hatch. Smash. Get Ducked.**

---

## ▶ HOW TO RUN IT (laptop, one time)

1. Have **Roblox Studio** + **Rojo** installed (see `LAUNCH.md`).
2. Put the newest `lucky-duck-dev` zip in your Downloads.
3. Run the one-button launcher in PowerShell:
   ```
   powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\GO.ps1"
   ```
   It unzips the newest build → pushes to GitHub → starts Rojo.
4. In Studio: **Rojo plugin → Connect → ▶ Play.**

To publish it live, follow **`PUBLISH.md`** (Part A = launch tonight).

---

## 📁 WHAT'S IN HERE

- `src/server/` — all game logic (47 services/builders)
- `src/client/` — all UI + effects (21 scripts)
- `src/shared/` — configs the client + server both read (12 modules)
- `launch-kit/` — `GO.ps1` (all-in-one), plus separate update/push/rojo scripts + their README
- `default.project.json` — Rojo mapping (don't edit)
- `LAUNCH.md` — first-time Studio setup
- `PUBLISH.md` — go-live steps + the 10-world split
- `BRANDING.md` / `SOCIAL.md` — store listing + marketing
- `ROADMAP.md` — planned systems needing a published game
- `landing/index.html` — the promo website (free Cloudflare Pages)

---

## 🎮 WHAT THE GAME HAS

**Spawn plaza:** VIP lounge, machine lobby (merge / gold / platinum / rainbow / enchant),
mini-games (spin / fortune / dice / chest), shops, all eggs, fishing pond, boss pad, world portals.

**World 1 — Grassland Odyssey (100 stages):**
- Never-flat terrain: rolling hills, tunnels, sky islands, ponds, mixed zones
- Swaying trees + flowing water; invisible outer border; camera ignores tall props
- Themed breakables (crates, rocks, trees, chests, bushes) + dark reward corners
- Rogue enemy ducks that chase & fight, scaling per stage
- Scaling shops / upgrade booths / merchants / mini-games / secret stashes (tier 1→5)
- Local **Duck Droppings** currency + per-draw gates

**Progression:**
- One-time **starter wheel**: 2 ducks (6 Common / 5 Uncommon / 2 Rare, 0.01% Huge)
- **4 active slots → 60** (gameplay) **→ 120** (Robux)
- **Mandatory rebirth ladder** every 10 stages: +30% attack each, re-locks gates
- Duck tiers Small → Huge → Gigantic → Titanic (real stat multipliers)

**Systems:** trading, clans, season pass, rotating events, achievements/titles, cosmetics
(trails/auras), potions, gift boxes, daily spin, leaderboards, anti-exploit rate-limiting.

**Currencies:** 💩 Shimmer Splats (premium) + 20 themed local droppings.

---

## ⚠️ NOTES
- Runs in **MEMORY MODE** (no saving) until you Publish + enable API — that's normal pre-launch.
- Robux items show "Soon" until you mint IDs and paste them into `src/shared/ShopConfig.lua`.
- Trading / clans / multi-player combat need a 2-player live test.
- The 10-place split needs publishing first (see `PUBLISH.md` Part B).

Repo: github.com/curiousstitches/Jeepers-Get-DUCKED-
