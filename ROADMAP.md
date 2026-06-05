# 🗺️ ROADMAP — planned systems (need multiplayer playtest before building)

These three are deliberately NOT built yet. Each carries real risk that demands a live 2-player
Studio test (which can't be done from a phone), or careful data architecture first. Building them
half-right would threaten the economy or save data. Here's the plan for each.

## 1) 🏝️ Player Plots / Duck Ponds
What: each player gets a decoratable plot (place ducks on display, furniture), visitable & rateable.
Why it waits: needs persistent plot storage + cross-server visiting (join-by-plot) + a moderation
pass on anything player-placed/named. Best built on ProfileStore (session-locked) so plot edits and
inventory can't desync or dupe.
Plan: (1) migrate PlayerData -> ProfileStore. (2) plot DataStore keyed by userId. (3) place/remove
ducks from inventory into plot slots (server-authoritative). (4) "visit" via TeleportService reserved
servers. (5) likes/ratings with one-per-visitor guard.

## 2) ⚔️ PvP Duck Battles
What: squad-vs-squad battles, ELO/ranking, optional wagers.
Why it waits: wagering ducks/currency is a prime dupe + scam target; auto-battle math needs balancing
against the leveling/enchant system we just added; matchmaking needs live testing with 2+ clients.
Plan: (1) start with NO wager — bragging/ELO only (safe). (2) auto-resolve from effectiveStrength +
randomness, server-side. (3) matchmaking queue. (4) ONLY after it's proven stable, add opt-in currency
wagers held in escrow server-side (never ducks, to avoid loss-of-collection rage + dupe vectors).

## 3) 💥 Shared Server-Wide Raid Bosses
What: one giant boss the whole server fights together (vs the solo Duck Titan we DID build).
Why it waits: shared HP must sync across all clients smoothly, damage attribution + reward splitting
need live load testing, and a stuck/duplicated boss could grief a server.
Plan: (1) single server-owned boss model, HP as an attribute replicated to all. (2) contribution table
{userId=damage}. (3) on death, reward everyone scaled by contribution. (4) cooldown + single-instance
lock. (5) load-test with multiple clients in Studio before shipping.

## Prerequisite for all three: ProfileStore migration
The current DataStore wrapper is solid for single-session play. Before plots/PvP/wagers, migrate to
**ProfileStore** for session-locking (prevents the same profile loading on two servers = the #1 dupe
exploit). This is a contained, well-documented swap — do it first, then the above unlock safely.
