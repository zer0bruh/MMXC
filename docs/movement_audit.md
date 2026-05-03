# Movement Audit: `player_controller.gd` vs MMXE

## Objective

Audit `scripts/core/player/player_controller.gd` against MMXE's player movement implementation in `C:\Users\Francois\Downloads\MMXE-main` to identify parity gaps, timing mismatches, behavioral differences, and likely bugs.

## Sources Reviewed

### Godot

- `scripts/core/player/player_controller.gd`

### MMXE

- `scripts/ComponentPlayerMove/ComponentPlayerMove.gml`
- `scripts/ComponentPhysics/ComponentPhysics.gml`
- `scripts/BaseCharacter/BaseCharacter.gml`
- `scripts/XCharacter/XCharacter.gml`
- `scripts/psxCharacter/psxCharacter.gml`
- `scripts/BootPartBase/BootPartBase.gml`
- `objects/obj_player/Create_0.gml`
- `objects/obj_player/Alarm_0.gml`

## Current Godot Feature Inventory

Implemented in `player_controller.gd`:

- Ground locomotion: `idle`, `walk`
- Air locomotion: `jump`, `fall`
- Ground dash: double-tap and dedicated dash input
- Dash end handling
- Wall slide and wall jump
- Shooting and charge release
- Charge visual effects and palette swapping
- Input buffering for jump and dash
- Double-tap dash detection
- Custom animation playback driven by MMXE animation JSON
- Custom stepwise collision / ledge-step movement intended to mirror MMXE physics

Not present as controller states or movement systems:

- `crouch`
- `ladder`, `ladder_enter`, `ladder_move`, `ladder_exit`
- `hurt`
- `death`
- `teleport_in`, `intro`, `intro_end`, `complete`, `outro`, `leave`
- `ride`
- `custom`
- boot-armor movement extensions such as `dash_air`, `dash_end_air`, `slide`, `slide_end`
- any armor/state-extension hook system comparable to MMXE's `character.init(self)` plus armor `step_armor_effects`

## MMXE Movement / State Architecture Summary

MMXE uses a componentized finite state machine:

- `ComponentPlayerMove` owns the locomotion FSM and input-triggered transitions.
- `ComponentPhysics` owns velocity, gravity, floor/ceiling/wall checks, and tile collision stepping.
- State tuning comes from character data (`BaseCharacter`, `XCharacter`, `psxCharacter`) and can be extended by armor scripts (`BootPartBase` and others).

Important architectural traits in MMXE:

- Ground and air behavior are split into states, but actual movement is data-driven through `self.states.*`.
- Core feel values in Godot already match MMXE defaults for X:
  - walk `376/256`
  - dash `885/256`
  - jump `1363/256`
  - gravity `0.25`
  - terminal velocity `6.25`
  - wall jump strength `5`
  - wall stick `5`
  - wall launch lock `11`
  - dash interval `32`
  - ground distance `3`
- MMXE behavior is also affected by:
  - settings toggles such as `Dash_On_Land` and `PSX_Style_Dash_Jumping`
  - armor parts that inject new states such as air dash and slide
  - damage / death / intro / outro transitions via publish/subscribe events

## Constants and Timing Comparison

| Mechanic | MMXE source | MMXE value | Godot value | Status | Notes |
|---|---|---:|---:|---|---|
| Gravity | `scripts/ComponentPhysics/ComponentPhysics.gml` | `0.25` | `0.25` | Match | Direct parity |
| Terminal velocity | `scripts/ComponentPhysics/ComponentPhysics.gml` | `6.25` | `6.25` | Match | Direct parity |
| Ground check distance | `scripts/ComponentPlayerMove/ComponentPlayerMove.gml` | `3` | `3` | Match | Used for jump / dash / floor transitions |
| Walk speed | `scripts/BaseCharacter/BaseCharacter.gml` | `376/256` | `376/256` | Match | X baseline matches |
| Dash speed | `scripts/BaseCharacter/BaseCharacter.gml` | `885/256` | `885/256` | Match | X baseline matches |
| Dash duration | `scripts/BaseCharacter/BaseCharacter.gml` | `32` frames | `32` frames | Match | `timer = CURRENT_FRAME + interval` equivalent |
| Jump strength | `scripts/BaseCharacter/BaseCharacter.gml` | `1363/256` | `1363/256` | Match | Negative vertical impulse in both |
| Wall jump strength | `scripts/BaseCharacter/BaseCharacter.gml` | `5` | `5` | Match | Direct parity |
| Wall stick delay | `scripts/BaseCharacter/BaseCharacter.gml` | `5` frames | `5` frames | Match | Direct parity |
| Wall launch lock | `scripts/BaseCharacter/BaseCharacter.gml` | `11` frames | `11` frames | Match | Direct parity |
| Ladder speed | `scripts/BaseCharacter/BaseCharacter.gml` | `376/256` | not implemented | Missing | Full ladder subsystem absent |
| Hurt horizontal speed | `scripts/BaseCharacter/BaseCharacter.gml` | `-138/256` | not implemented | Missing | Used by `hurt` state |
| Shoot cooldown | not found in reviewed MMXE move scripts | unknown from reviewed files | `8` frames | Unknown | Needs weapon script audit for parity |
| Charge thresholds | not found in reviewed MMXE move scripts | unknown from reviewed files | `30 / 105 / 180 / 255` | Unknown | Charge system exists in Godot, but not validated against MMXE weapon code here |
| Dash-on-land toggle | `global.settings.Dash_On_Land` | configurable | `false` constant | Partial | Godot hardcodes one MMXE setting state |
| PSX dash-jump toggle | `global.settings.PSX_Style_Dash_Jumping` | configurable | emulated by `DASH_JUMP_PRESS_GRACE_FRAMES = 2` | Approximation | Similar intent, but not the same rule |

## Detailed Gap Analysis

### 1. Missing States and Transitions

#### Critical: Hurt / knockback state is missing

**MMXE**

- Has wildcard `t_hurt -> hurt` transition in `ComponentPlayerMove`.
- `hurt` plays animation and applies knockback with `self.physics.set_speed(self.dir * self.states.hurt.speed, -2)`.
- `hurt` returns to `idle` on animation end.
- Damage events are wired through `self.subscribe("took_damage", function() { self.fsm.trigger("t_hurt") })`.

**Godot**

- No `hurt` state, no damage-triggered transition path, no knockback timer/animation handling.

**Impact**

- Core combat feel is incomplete.
- Enemy collisions or hazards cannot produce canonical MMX recoil behavior.
- Missing hurt recovery also blocks later invulnerability and death flow parity.

#### Critical: Ladder system is entirely missing

**MMXE**

- Supports `ladder`, `ladder_enter`, `ladder_move`, `ladder_exit`.
- Enter condition: while in `fall`, `idle`, `walk`, `dash`, or `walljump`, if vertical input is pressed and player overlaps `obj_ladder`.
- Ladder zeroes gravity and speed.
- `ladder_move` uses `self.vdir * self.states.ladder.speed`.
- Exit occurs when no longer overlapping ladder or when grounded.

**Godot**

- `vdir` is hardcoded to `0`.
- No ladder detection, no ladder states, no gravity suppression, and no transition logic.

**Impact**

- Entire traversal category missing from engine rebuild.

#### Important: Crouch state missing

**MMXE**

- `idle -> crouch` on down input.
- Crouch locks movement to zero, updates facing if horizontal input changes, and returns to `idle` when down is released.
- Also serves as the post-slide landing state in armor-enabled movement.

**Godot**

- No crouch input path and no crouch state.

**Impact**

- Noticeable control gap even before slide is ported.

#### Important: Death / intro / outro / ride / custom states missing

**MMXE**

- Includes `teleport_in`, `intro`, `intro_end`, `complete`, `outro`, `leave`, `death`, `ride`, and `custom`.

**Godot**

- None of these exist in the current controller.

**Impact**

- Not all are core-movement feel issues, but they are part of full player-state parity.

#### Important: Armor-driven movement extensions are absent

**MMXE**

- `XCharacter` adds dash and wall-jump on init.
- `BootPartBase` can add:
  - `dash_air` / `dash_end_air`
  - `slide` / `slide_end`
- Armor effects also reset or replenish movement resources each step.

**Godot**

- Controller is monolithic with no extension point for character / armor scripts to add states or alter tuning.

**Impact**

- Prevents parity with second armor / boot-based mobility.
- Makes future ports harder because MMXE movement is extensible, while Godot is currently hardcoded.

### 2. Behavioral Differences in Existing States

#### Critical: Wall-jump wall detection behavior is not equivalent

**MMXE**

- `get_wall_jump_dir()` returns:
  - `0` if grounded
  - `1` if `check_wall(9)`
  - `-1` if `check_wall(-9)`
- It does **not** require the player to be holding toward the wall.
- Wall slide entry only requires `self.hdir != 0 && self.physics.check_wall(self.hdir)`.

**Godot**

- `_get_wall_jump_dir()` requires directional input:
  - returns `1` only if `hdir == 1` and body probes hit right wall
  - returns `-1` only if `hdir == -1` and body probes hit left wall
- `_wall_slide_possible()` also requires `hdir != 0`, but additionally requires `not _is_on_floor()` and `_has_body_wall_contact(hdir)` with 2-of-3 sample probes.

**Impact**

- Godot is stricter than MMXE:
  - wall-jump may fail when touching a wall but not actively holding into it exactly the way MMXE allows
  - body-probe requirement may reject valid MMXE wall contacts
- This directly changes feel and responsiveness.

#### Critical: Dash activation collision gate is incomplete

**MMXE**

- Wildcard dash transition requires:
  - no wall in dash direction
  - on floor
  - not embedded in solid: `!self.physics.check_place_meeting(self.get_instance().x, self.get_instance().y, obj_square_16)`

**Godot**

- `_trigger_dash()` checks wall and floor, but does not guard against currently overlapping a blocker.

**Impact**

- Edge cases can allow dash entry in positions MMXE explicitly blocks.

#### Important: Dash-jump rule is approximated, not actually MMXE-configurable

**MMXE**

- Jump inherits dash speed if previous state is `dash` or `dash_air`, or if dash is currently held and `global.settings.PSX_Style_Dash_Jumping` is enabled.

**Godot**

- Jump inherits dash speed if previous state is `dash` **or** if dash was pressed within `2` frames via `_has_recent_dash_jump_press()`.

**Impact**

- Similar but not identical:
  - MMXE uses a user setting and held dash logic.
  - Godot uses a fixed press-grace heuristic.
- This can create timing mismatches on dash-jump feel and input leniency.

#### Important: Wall-slide contact test is probably stricter than MMXE

**MMXE**

- `wall_slide_possible()` is simply `self.hdir != 0 && self.physics.check_wall(self.hdir)`.

**Godot**

- Requires `_has_body_wall_contact(hdir)` with 3 probe points and at least 2 hits.

**Impact**

- May reject wall slides on narrow wall contact, corners, or near ledges that MMXE would accept.

#### Important: Land state horizontal movement differs slightly in entry behavior

**MMXE**

- `land` only sets animation and re-enables input buffer.
- Horizontal movement is then driven by transition to `walk` or later state logic.

**Godot**

- On entering `land`, it immediately sets `current_hspd = WALK_SPEED`, and if `hdir != 0` and no wall, sets `hspd` immediately.

**Impact**

- Small but noticeable difference in landing feel; Godot may preserve or reassert movement earlier than MMXE.

#### Important: Idle state force-resets vertical speed

**MMXE**

- `idle` enter sets full speed `(0,0)` because entering idle only happens in safe grounded contexts.

**Godot**

- Same behavior, but because the controller is simplified and some missing states collapse into idle/fall, this may hide bugs rather than mirror intended flow.

**Impact**

- Not necessarily wrong right now, but worth revisiting once hurt, crouch, ladder, and slide are added.

#### Nice-to-have: Dash audiovisual hooks missing

**MMXE**

- Dash spawns particles on enter and dust every 6 frames.
- Jump from dash spawns spark particle.
- Wall slide / wall jump also spawn particles and play sounds.

**Godot**

- Movement logic implements timings but not these movement-specific particles/sounds in the controller.

**Impact**

- Does not break mechanics, but reduces perceived fidelity and responsiveness.

### 3. Missing MMXE Features Not Yet Ported

#### Critical: Air dash (`dash_air`) missing

**MMXE**

- Added by boot armor in `BootPartBase`.
- Available only in air.
- Has its own interval (`15`), gravity suppression, limited use count, and reset conditions on landing or wall slide.

**Godot**

- No air dash state, no aerial dash resource tracking, no state extension mechanism.

**Impact**

- Major feature gap for armor-based progression / advanced movement parity.

#### Critical: Slide (`slide`) missing

**MMXE**

- Added by boot armor in `BootPartBase`.
- Swaps to `spr_slide_mask`, moves at dash-like speed, has ceiling bailout logic, and ends into crouch.

**Godot**

- No slide state, no temporary collision-mask swap, no crouch destination state.

**Impact**

- Major feature gap tied to a core X upgrade path.

#### Important: Hurt → death pipeline not present

**MMXE**

- Damage can trigger hurt; death disables gravity/input and runs palette / particle / room-transition flow.

**Godot**

- No corresponding pipeline in controller.

**Impact**

- More than polish; this blocks gameplay-complete player behavior.

#### Important: Character / armor state injection missing

**MMXE**

- `BaseCharacter` supplies defaults.
- `XCharacter` adds dash/wall-jump by capability.
- Other characters or armor can alter speeds or add states.

**Godot**

- All locomotion is compiled into one script with fixed constants.

**Impact**

- Limits parity for alternate characters and upgrade systems.

### 4. Likely Bugs or Risk Areas in Current Godot Port

#### Critical: `dash_dir` assignment inside dash enter can overwrite requested dash direction

**MMXE**

- On dash enter, `self.dash_dir = self.dir; if(self.dash_dir == 0) self.dash_dir = self.hdir;`
- This works because the FSM trigger path already set `self.dash_dir` from double-tap, and MMXE facing / xscale handling is tightly coupled.

**Godot**

- `_trigger_dash()` computes `candidate_dir`, stores `dash_dir = candidate_dir`, then `_change_state("dash")`.
- Inside `_enter_state("dash")`, Godot immediately does:
  - `dash_dir = dir`
  - if zero, use `hdir`
- That can discard the candidate direction that `_trigger_dash()` just selected.

**Impact**

- Risk of incorrect dash direction when facing and input differ, especially with double-tap timing.

#### Important: Wall-jump transition condition copied imperfectly

**MMXE**

- Transition: `(!jump || is_on_ceil()) && self.timer > 10 || vspd > 0`
- `self.timer` is an absolute frame index. Since it stores `CURRENT_FRAME` at state enter, `self.timer > 10` is almost always true after the first moments of gameplay, so effectively the transition becomes:
  - released jump / hit ceiling OR falling downward

**Godot**

- Uses `(((not _get_input("jump")) or _is_on_ceil()) and frame_counter - timer > 10) or vspd > 0.0`

**Impact**

- Godot is probably closer to intended design than MMXE's literal code, but it is **not** source-identical.
- If the goal is strict MMXE emulation, this is a behavioral difference that should be called out explicitly.

#### Important: Wall-slide floor check differs from MMXE helper

**MMXE**

- `wall_slide_possible()` itself does not test floor; floor exclusion happens through transition graph ordering.

**Godot**

- `_wall_slide_possible()` includes `not _is_on_floor()`.

**Impact**

- Usually harmless, but can differ in edge cases during landing or tile seams.

#### Important: Vertical input is currently disabled by design

**MMXE**

- `vdir = down - up`, used for ladders and related transitions.

**Godot**

- `_update_axes()` always sets `vdir = 0`.

**Impact**

- Confirms ladder and down-state systems cannot work even if partially added elsewhere.

#### Nice-to-have: MMXE exposes data-driven tuning, Godot hardcodes it

**MMXE**

- Speeds and timings are state data, not hardcoded in the movement component.

**Godot**

- Values are constants at top of controller.

**Impact**

- Not a bug yet, but increases divergence risk as soon as character variants or upgrades are ported.

## Priority Fix List

### Critical

1. **Add hurt / knockback state and damage transition plumbing**
   - Why: missing core combat response and movement interruption.
   - Touchpoints: `player_controller.gd` state table, external damage event integration, animation/physics response.
   - Validate: enemy hit should apply horizontal recoil and vertical pop, then cleanly recover.

2. **Add ladder system (`ladder_enter`, `ladder`, `ladder_move`, `ladder_exit`)**
   - Why: entire traversal mechanic missing.
   - Touchpoints: vertical input handling, ladder overlap detection, gravity suppression, animation transitions.
   - Validate: enter from ground/air, pause on ladder, move up/down, exit at top/bottom/floor.

3. **Rework wall contact logic to match MMXE more closely**
   - Why: current wall slide/jump responsiveness is stricter than source.
   - Touchpoints: `_wall_slide_possible()`, `_get_wall_jump_dir()`, wall probes.
   - Validate: wall jump and wall slide should trigger in all MMXE-valid contact scenarios.

4. **Fix dash entry direction preservation**
   - Why: candidate dash direction can be overwritten on state entry.
   - Touchpoints: `_trigger_dash()`, `_enter_state("dash")`.
   - Validate: dash starts in intended direction for button dash and double-tap dash across facing mismatches.

5. **Implement armor-driven air dash and slide capability path**
   - Why: major MMXE mobility features missing, especially for X armor progression.
   - Touchpoints: controller state model or a new extensibility layer.
   - Validate: air dash count/reset and slide hitbox behavior match MMXE.

### Important

1. **Add crouch state**
   - Why: noticeable baseline control gap and prerequisite for slide parity.

2. **Replace fixed dash-jump grace with MMXE-style configurable rule**
   - Why: current approximation may feel off versus source behavior.

3. **Match land-state movement behavior more closely**
   - Why: current immediate horizontal assignment may slightly alter landing feel.

4. **Add death pipeline and related state handling**
   - Why: necessary for full player lifecycle parity.

5. **Refactor movement constants into data/state definitions**
   - Why: needed for alternate characters, armor modifiers, and easier parity maintenance.

### Nice-to-have

1. **Add dash / wall / landing particles and sound hooks**
   - Improves movement readability and feel.

2. **Port intro / outro / ride / custom state handling**
   - Needed for completeness but not first-order movement feel.

3. **Audit charge/shoot timing against MMXE weapon scripts**
   - Current audit focused on movement controller; charge timing parity remains unverified.

## Suggested Verification Checklist After Fixes

- Ground dash starts, sustains, and exits on the same frames as MMXE.
- Dash jump preserves horizontal speed under the same conditions as MMXE settings.
- Wall slide enters on all valid wall contacts and exits correctly on release / landing / separation.
- Wall jump launches after the correct stick delay and respects launch lock.
- Hurt state interrupts movement and recovers on animation end.
- Ladder entry/idle/move/exit flows work from both ground and air.
- Armor-enabled slide and air dash follow MMXE resource and collision rules.
- No state conflicts occur between shooting/charging and movement transitions.

## Traceability: Step → Targets → Verification

| Step | Targets | Verification |
|---|---|---|
| Read Godot controller | `scripts/core/player/player_controller.gd` | Full implemented-state inventory and constants extracted |
| Read MMXE move logic | `scripts/ComponentPlayerMove/ComponentPlayerMove.gml`, `scripts/ComponentPhysics/ComponentPhysics.gml` | FSM, transitions, helpers, and physics flow mapped |
| Read tuning sources | `scripts/BaseCharacter/BaseCharacter.gml`, `scripts/XCharacter/XCharacter.gml`, `scripts/psxCharacter/psxCharacter.gml`, `scripts/BootPartBase/BootPartBase.gml` | Baseline constants and extension mechanics mapped |
| Compare parity | Godot vs MMXE | Each gap documented as MMXE behavior vs Godot behavior |
| Produce remediation list | `docs/movement_audit.md` | Prioritized backlog categorized as Critical / Important / Nice-to-have |

## Summary

The current Godot controller successfully mirrors MMXE's **core X ground/air tuning values** and the **basic state set** for walk, jump, dash, wall slide, wall jump, and fall. The biggest remaining parity issues are not raw constants but **missing systems** (hurt, ladder, crouch, armor-driven air dash/slide), **stricter wall interaction logic**, and a few **behavioral mismatches** such as dash-jump rules and dash-direction preservation.