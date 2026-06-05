# 🎨 CUSTOM MODELS GUIDE — getting PS99-quality 3D into your game

Your game looks PS99-*inspired* (bright, chunky, glowy) but uses Roblox basic parts. To get true
detailed pets/eggs like PS99, you need custom **meshes**. Here's how — and exactly where I help.

## The split: YOU place, I program
- **You** do the Studio clicking (find/drag/upload a model) — that needs hands-on Studio.
- **I** write all the code around it (spawn it, make it follow you, scale per tier, swap per rarity).
- The handoff: once a model is in your game, tell me its **name** (in Explorer) or **asset ID**.

## Option 1 — Free Toolbox models (start here, easiest)
1. In Studio: top menu **View → Toolbox**.
2. In the Toolbox search bar, type things like: `rubber duck`, `low poly egg`, `cartoon pet`, `jeep`.
3. Filter to **Models** or **Meshes**. Pick one with a good thumbnail + decent ratings.
4. **Drag it into the Workspace.** It appears in the Explorer as a Model or MeshPart.
5. Rename it something clear (right-click → Rename), e.g. `DuckMesh_Common`.
6. Move it into **ReplicatedStorage** (drag it there in Explorer) so the code can clone it.
7. **Tell me the name.** I'll write code to clone it onto players, scale it for Small→Titanic, etc.

⚠️ Toolbox safety: only use models with no scripts inside (right-click → check for Script objects;
delete any). Free models occasionally hide junk scripts — I can tell you how to verify one.

## Option 2 — AI image-to-3D (for unique ducks)
- Tools: **Meshy.ai**, **Roblox's built-in Material/Avatar AI**, or similar.
- Make/great a duck image → the tool outputs a `.obj`/`.fbx` mesh → upload to Roblox
  (Studio: **Asset Manager → Meshes → Import**). You get an asset ID.
- Tell me the ID; I wire it in. (Quality is hit-or-miss; good for special pets, not all 1000.)

## Option 3 — A real 3D artist / Blender (best, most effort)
- Only if you want fully bespoke art. Model in Blender → export → upload. Same handoff to me.

## What I do once a mesh exists (the behind-the-scenes code)
- Replace the parts-based duck with your mesh in `DuckModelBuilder`.
- Clone + weld it to follow the player (pet system).
- Scale it by tier (Small 0.5x → Titanic 8x) and tint by rarity.
- Swap eggs to your mesh in the hatcher pods.
- Keep it performant (StreamingEnabled + render caps already in place).

## Recommended path for you
1. Launch with the current polished parts-based look (it's good + bright).
2. After launch, grab 4-5 free Toolbox duck/egg meshes for the most-seen ones.
3. Send me their names → I swap them in. Instant visual upgrade, no full re-art.
