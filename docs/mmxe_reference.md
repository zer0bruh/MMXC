# MMXE Reference Notes

This document summarizes the useful parts of `C:\Users\Francois\Downloads\mmxe-main` that we can use as reference while rebuilding the runtime in Godot.

## Project scale snapshot

- `objects`: 226 files across 87 directories
- `scripts`: 1184 files across 592 directories
- `sprites`: 1916 files across 1080 directories
- `rooms`: 204 files across 18 directories
- `tilesets`: 20 files across 10 directories
- `datafiles`: 1455 files across 118 directories

## What MMXE clearly gives us

- Playable-system reference for movement, dash, wall jump, weapons, menus, and stage flow
- Sprite sheets plus animation metadata for X, Zero, UI, stage art, enemies, weapons, and capsules
- Layered armor sprite sets for X with separate `helm`, `body`, `arms`, and `legs` folders
- Character metadata describing which armor parts exist and what they do
- Stage capsule visuals and armor select UI art

## X animation and armor art

Base X art lives in:

- `datafiles/sprites/x/normal`
- `datafiles/sprites/x/animation.json`

Layered armor art lives in:

- `datafiles/sprites/x/armor/x1`
- `datafiles/sprites/x/armor/x2`
- `datafiles/sprites/x/armor/x3`
- plus later-era sets such as `blade`, `hermes`, `falcon`, `icarus`, `ult`, `x7`, `x8_ult`

Important structure detail:

- Each armor family is split into `arms`, `body`, `helm`, and `legs`
- The files mirror the base X animation names, which makes layered replacement practical
- `datafiles/sprites/x/animation.json` declares the animation layer model:
  `normal`, `legs`, `helm`, `body`, `arms`

This is exactly the kind of layout we want for Godot too.

## How MMXE applies armor

The main armor application flow is in:

- `scripts/ComponentPlayerMove/ComponentPlayerMove.gml`

Key behavior from `apply_full_armor_set()`:

- It starts with base `/normal` art
- It turns selected armor ids into armor-part structs
- Each armor part contributes a `sprite_name` like `/x1/helm` or `/x2/arms`
- Those paths are converted into animation subdirectories under `sprites/x/armor/...`
- Armor effect code is applied to gameplay state at the same time
- The animation component is told which armor layers are active via `armor_set`

In other words:

- Visual armor is layered data, not separate full-body sprites
- Armor gameplay effects are attached to part structs, not hardcoded into one big X script

## Armor part scripts

Base classes:

- `scripts/ArmorBase/ArmorBase.gml`
- `scripts/HeadPartBase/HeadPartBase.gml`
- `scripts/BodyPartBase/BodyPartBase.gml`
- `scripts/ArmsPartBase/ArmsPartBase.gml`
- `scripts/BootPartBase/BootPartBase.gml`

Representative concrete sets:

- `scripts/XFirstArmor/XFirstArmor.gml`
- `scripts/xSecondArmor/xSecondArmor.gml`
- `scripts/XHermesArmor/XHermesArmor.gml`
- `scripts/xBladeArmor/xBladeArmor.gml`

Patterns these scripts show:

- `Head` parts mostly add special behavior or none
- `Body` parts usually modify damage handling
- `Arms` parts swap buster behavior and charge rules
- `Boots` parts add movement states such as faster dash, air dash, slide, or mach dash

This is the best reference for how we should model armor data in Godot:

- one resource per armor part
- separate visual path data
- optional gameplay hooks by part category

## Capsules

MMXE does include capsule assets and capsule objects.

Relevant references:

- `objects/obj_capsule`
- `objects/spawn_capsule`
- `datafiles/sprites/stage/animation.json`
- `datafiles/sprites/stage/normal/spr_stage_capsule_strip4.png`
- `datafiles/sprites/stage/light/spr_light_capsule_*`

What the inspected files show:

- `spawn_capsule` swaps the entity to the `stage` character art and plays the `capsule` animation
- `obj_capsule` itself is just the animated object shell with `ComponentAnimation`
- The direct unlock/application logic is not embedded in `obj_capsule` alone

Inference:

- The capsule object is the presentation layer
- The actual reward flow is likely driven by stage scripting, interaction logic, dialogue, or weapon/armor grant flow elsewhere
- MMXE also contains `obj_armor_giver`, but that looks like a simpler test/helper object rather than the full capsule experience

For our Godot version, the clean model is:

- Capsule scene for visuals, collision, hologram, and dialogue hooks
- Reward resource describing armor part, weapon, heart tank, or upgrade granted
- Save/progression service that marks the reward as collected
- Player appearance refresh that reapplies active armor layers

## Character defaults and armor slots

Relevant files:

- `scripts/BaseCharacter/BaseCharacter.gml`
- `scripts/XCharacter/XCharacter.gml`
- `scripts/global_init/global_init.gml`

Important details:

- X declares `possible_armors` grouped by head, arms, body, boots, and full set
- Global armor state is stored as slot indices
- The player later resolves those indices into real armor-part structs

That means our Godot save data should probably store:

- current character id
- armor slot selections
- collected upgrades
- stage progression and unlocked weapons

Not raw sprite paths.

## Animation layering reference

Relevant files:

- `scripts/ComponentAnimation/ComponentAnimation.gml`
- `scripts/ComponentSpriteRenderer/ComponentSpriteRenderer.gml`
- `datafiles/sprites/x/animation.json`

MMXE’s layered draw model is:

1. Draw base action from the current animation
2. Draw active armor overlay actions for matching animation/frame
3. Use metadata like `shot_offset_x` and `shot_offset_y` from animation keyframes

That strongly suggests our Godot direction should be:

- keep animation definitions as editable resources
- keep layer-capable sprite composition in code
- keep armor visual overlays data-driven

## Recommendation for Godot architecture

Use MMXE as a reference for data shape, not a direct code port.

Recommended Godot breakdown:

- `PlayerController`: movement/state/inputs only
- `PlayerAppearance`: base animation + armor layer composition
- `ArmorPartData` resources: category, sprite path prefix, gameplay modifiers
- `CapsuleRewardData` resources: what a capsule grants
- `Capsule` scene: visuals + interaction + reward handoff
- `ProgressionData`: collected upgrades, armor ownership, active loadout

## Immediate follow-up work

1. Build a proper `PlayerAppearance` layer system so X can wear base, X1, X2, and X3 parts in Godot.
2. Convert the current single-layer X animation resource into the first editable appearance asset.
3. Add a capsule reward resource format before building the first capsule scene.
4. Move test-room geometry into editable TileMap content.
