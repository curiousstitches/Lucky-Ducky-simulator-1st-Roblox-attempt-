# 🚀 PUBLISH GUIDE — Jeepers-Get-DUCKED (launch + the 10-world split)

Follow in order. This takes your single-place build live, then (optionally) splits the 10 worlds
into separate places for performance. Do PART A to launch tonight. Do PART B later when ready.

═══════════════════════════════════════════════
PART A — PUBLISH & GO LIVE (do this to launch)
═══════════════════════════════════════════════

1) In Studio with the game open (Rojo connected, you can Play):
   File → Publish to Roblox As… → name it "Jeepers-Get-DUCKED" → Create.

2) Turn ON saving + purchases:
   File → Game Settings → Security →
     ✅ Enable Studio Access to API Services
     ✅ Allow HTTP Requests
   Save. (This makes DataStore saving work — progress now persists.)

3) Make it public:
   create.roblox.com/dashboard → your game → ⚙ → Playability → Public.

4) MONETIZATION (so the Robux items work). For EACH pass/product:
   create.roblox.com/dashboard → your game → Monetization →
     - Passes (create each): VIP, Open5, Open10, AutoCollect, x2Forever, LuckX2,
       FastTravel, Season Premium, +Slots60-120 packs.
     - Developer Products (create each): egg/ability/potion buys, MEGA potion, diamond packs.
   Copy each ID. Paste them over the `0` placeholders in:
     src/shared/ShopConfig.lua  (GamePasses + ExtraProducts + DeveloperProducts `id = 0`)
   Re-push (GO.ps1), re-publish. Now purchases work.

5) Playtest live with a friend (trading, clans, enemies need 2 players). Fix anything, re-push, re-publish.

DONE = launched. Everything works in one place.

═══════════════════════════════════════════════
PART B — SPLIT INTO 10 PLACES (later, for scale)
═══════════════════════════════════════════════
Why: separate places keep each world fast and memory-light on phones. Only do this after Part A
is stable, because places only exist once published.

1) Create 10 places under your universe:
   Creator Dashboard → your experience → Places → Create New Place (x10):
   World1 … World10. Each gets its own Place ID (a number). Write them down.

2) Tell me the 10 Place IDs. I will:
   - add a `Places.lua` config mapping World N → its Place ID,
   - wire `TeleportService` so each world portal in the spawn plaza sends the player to that place,
   - move each World builder into its own place's startup (so only that world loads there),
   - add cross-place data via ProfileStore session-locking (prevents dupes; needs published game),
   - keep the spawn plaza as the universe's "start place."

3) Re-push each place build, publish each. Portals now load real separate worlds.

NOTE: Part B is the only part I cannot pre-build — it needs the 10 real Place IDs that don't exist
until you make them in step B1. Everything else is already built and structured to split cleanly.
