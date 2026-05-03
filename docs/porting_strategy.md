# Porting Strategy

## Core principles

1. Use MMXE as a reference, not as a codebase to translate line-by-line.
2. Keep the Godot project data-driven so sprites, animation metadata, hitboxes, and stage content can evolve without rewriting core systems.
3. Build the collection around a shared `core` layer and game-specific content packs for MMX1, MMX2, and MMX3.
4. Finish one vertical slice first. A good first slice is player movement, one enemy, one weapon, one short stage chunk, HUD, and pause flow.

## Recommended phase order

### Phase 0: Ingest and classify

- Inventory sprites, tilesets, sounds, music, rooms, and major systems from MMXE.
- Identify what belongs in `core`, what belongs in a per-game content pack, and what should be replaced entirely.
- Document naming conventions before importing anything at scale.

### Phase 1: Core movement slice

- Character controller with walk, jump, dash, wall jump, camera, and collisions.
- Basic animation graph and state machine.
- One test room with slopes, moving platforms, hazards, and checkpoint handling.

### Phase 2: Combat slice

- Buster shots, charge levels, damage, invulnerability, pickups, and HUD.
- One enemy family and one miniboss-quality encounter.
- Reusable hurtbox / hitbox / projectile framework.

### Phase 3: Stage-content pipeline

- Tileset import flow.
- Room-to-scene conversion strategy.
- Parallax/background layers and stage scripting hooks.

### Phase 4: Meta systems

- Stage select.
- Weapon get flow.
- Armor capsules and progression save data.
- Collection shell for selecting MMX1 / MMX2 / MMX3.

### Phase 5: Expand to trilogy

- Promote anything reused into `core`.
- Keep game-specific stage logic and content isolated in per-game folders.
- Resist feature creep from later series entries until the SNES baseline is stable.

## Suggested Godot structure

- `scenes/main`: app bootstrap and collection shell scenes.
- `scenes/core`: reusable gameplay scenes such as player, projectiles, enemies, HUD, triggers.
- `scripts/core`: engine-level scripts and state machines.
- `data/core`: shared gameplay data resources.
- `data/games/mmx1`, `data/games/mmx2`, `data/games/mmx3`: game-specific content.
- `assets/raw`: untouched source dumps or manually curated placeholder art.
- `assets/imported`: normalized art ready for Godot.
- `tools`: importers, validators, and conversion scripts.

## Immediate next backlog

1. Define the player controller API in Godot around SNES-accurate movement.
2. Create an asset importer for MMXE sprites and tilesets.
3. Decide how stage data will live in Godot: native TileMap scenes, custom JSON, or a hybrid.
4. Build one test map focused on movement feel before any collection UI.

## Asset triage

- Highest priority: player sprites, collision masks, tilesets, HUD pieces, core SFX.
- Medium priority: one enemy set, one boss set, one short stage background stack.
- Later priority: stage select art, dialogue portraits, collection shell presentation, optional extras.

## Caution areas

- GameMaker rooms should be treated as source reference, not a guaranteed direct import target.
- Gameplay feel matters more than system count early on.
- Audio, palette behavior, and hitbox timing can drift quickly if they are not captured in data.
