# Movement

> **Status**: Revised (post design-review 2026-06-02)
> **Author**: Design session + agents
> **Last Updated**: 2026-06-02
> **Implements Pillar**: Pillar 4 (Motion Is the Answer)
> **Layer**: Core (Gameplay) | **Priority**: MVP | **Design Order**: #5

## Overview

Movement is the physics and state machine layer that translates player intent into character motion in Ashen Maple's 2D sidescrolling world. At the infrastructure level, it owns every frame-to-frame position change the player character makes: horizontal walking velocity driven by `move_speed` from Character Stats, gravity-governed vertical velocity with a single jump, dodge roll trajectory and I-frame window management, ladder and rope climbing, and drop-through platform handling. Every downstream system that cares about where the player is, how fast they're moving, or whether they're invulnerable reads from Movement — it is the authoritative source of position, velocity, and movement state for the player character. Dodge roll is a three-system collaboration: Movement owns the velocity and I-frame timing; Stamina owns the cost gate; Combat reads the `i_frames_active` flag when resolving incoming hits.

At the player level, Movement is the moment-to-moment physical vocabulary of Pillar 4: Motion Is the Answer. Standing still is death — and this system is what makes motion feel fast, precise, and consequential. A player who has mastered Movement knows exactly how far a dodge roll carries them, times their jump arc to clear an enemy sweep, and uses the speed burst of a roll to reposition after a parry. Movement's responsiveness — the absence of input lag, the clean snap from walk to dodge to idle — is the physical foundation of the entire combat loop. When it works, players never think about it; when it fails, they blame the controls.

## Player Fantasy

Movement's player fantasy is not about moving — it's about surviving. Players don't think "I love how my character moves"; they think "I dodged that." The fantasy Movement delivers is the same promise Pillar 4 makes: that the world's danger is negotiable, and that surviving it is a skill you built, not a roll you got lucky on.

**The clean escape.** An enemy telegraphs a heavy strike. The player reads the wind-up, presses dodge at the right moment, and the I-frame window swallows the hit. The character is already repositioning as the attack whiffs. Nothing was tanked. Nothing was lucky. The player made a spatial decision and Movement executed it without friction. That frictionless execution is the fantasy — the moment between "I see it" and "I survived it" with nothing between them but the player's read.

**The class that moves differently.** When a Warrior player switches to a Thief build, Movement should feel faster before they ever open the stat screen. The class speed delta (Thief 145 u/s vs. Warrior 120 u/s) must be perceptually real — felt in how quickly you close on an enemy and how much ground a single dodge roll covers — not just a tooltip change. Class identity lives in Movement as much as in Combat.

Movement fails its fantasy when: dodge timing feels disconnected from the button press, jump arcs feel imprecise, or the character gets caught on geometry mid-reposition. The player should never be thinking about the input system or the physics. They should only be thinking about the enemy.

## Detailed Design

### Core Rules

**1. Horizontal Walking**

Horizontal velocity is set directly from the X component of `Input.get_vector("move_left", "move_right", "move_up", "move_down")` each physics frame:

`velocity.x = input_x_snapped × move_speed`

`input_x_snapped` is 0.0, −1.0, or 1.0 — the 8-directional snap from Input & Controls guarantees no fractional values. `move_speed` is read from Character Stats each frame (responds immediately to buffs/gear changes). There is no acceleration ramp: the character reaches full speed in one physics frame. Deceleration is also instant: releasing input sets `velocity.x = 0` immediately.

Horizontal walking is suppressed (velocity.x forced to 0) during: PARRY_LOCKED, HIT_STUN, DODGING, DEAD, CLIMBING, and HEALING.

---

**2. Gravity and Airborne State**

Gravity is applied every physics frame when `is_on_floor()` returns false:

`velocity.y += GRAVITY × delta`
`velocity.y = min(velocity.y, TERMINAL_VELOCITY)`

`GRAVITY = 980.0 u/s²` (tunable constant, owned by this GDD). `TERMINAL_VELOCITY = 1200.0 u/s` (tunable cap; prevents Jolt physics tunneling through thin platforms on extreme falls — not reached in normal geometry, which expects falls under ~1.5s). The player is considered grounded when `is_on_floor()` returns true via `CharacterBody2D.move_and_slide()`.

---

**3. Jump**

Jump is available when either:
- `is_on_floor()` is true (grounded), OR
- Within the coyote window: `COYOTE_JUMP_FRAMES` physics frames after the player leaves the floor without having jumped

On `is_action_just_pressed("jump")` in a valid jump state: `velocity.y = -JUMP_VELOCITY`

`JUMP_VELOCITY = 480.0 u/s` (tunable; gives ~117 unit apex height with GRAVITY = 980). `COYOTE_JUMP_FRAMES = 4` (67 ms at 60 fps; tunable independently of ladder re-grab suppression).

No double jump in MVP. Jump is not cancelable mid-arc.

---

**4. Dodge Roll**

Available from: IDLE, RUNNING (grounded states only). Not available while airborne, climbing, in parry lock, hit stun, or dead.

**Direction:** The X component of directional input at the moment `InputResolver` grants the dodge action determines the roll direction. If input is neutral (no horizontal input), the dodge rolls in `facing` direction.

**Velocity during dodge:** `velocity.x = dodge_dir × move_speed × DODGE_SPEED_MULTIPLIER`

`DODGE_SPEED_MULTIPLIER = 2.2` (tunable; gives ~2.2× walk speed burst). Vertical velocity (`velocity.y`) is not modified — dodge does not cancel gravity or a falling arc.

**Duration:** DODGE_DURATION = 0.45s. Horizontal velocity is locked at dodge velocity for the full duration; player cannot redirect.

**I-Frame window:** Managed by Movement, queried by Combat:

- `i_frames_active = false` initially
- Set `true` when elapsed time ≥ `dodge_iframes_delay` (base 0.08s from Character Stats)
- Set `false` when elapsed time ≥ `dodge_iframes_delay + dodge_iframes` (base 0.08 + 0.22 = 0.30s)
- On dodge end (0.45s): `i_frames_active = false` (guaranteed)

`dodge_iframes_delay` and `dodge_iframes` are read from Character Stats at the moment the dodge begins.

---

**5. Parry Lock**

When `InputResolver` grants `parry`:
- Movement enters PARRY_LOCKED state
- `velocity.x = 0` for the full parry animation duration (`PARRY_DURATION`)
- `PARRY_DURATION = parry_window + PARRY_RECOVERY` where `parry_window` is read from Character Stats (base 0.35s, gear-modifiable) and `PARRY_RECOVERY = 0.15s` is a constant (not gear-modifiable)
- At base values: `PARRY_DURATION = 0.35 + 0.15 = 0.50s` total movement lock
- **Success phase** (elapsed < `parry_window`): Combat evaluates incoming hits for parry success
- **Recovery phase** (elapsed ≥ `parry_window`, elapsed < `PARRY_DURATION`): success window is closed; hits taken here apply hit stun normally; player remains movement-locked
- `velocity.y` continues under gravity; parry is grounded-only (granted from IDLE/RUNNING only)
- **Floor-loss during PARRY_LOCKED:** If `is_on_floor()` becomes false after parry-grant (e.g., ledge edge, one-frame Jolt contact delay), Movement immediately transitions to FALLING and cancels PARRY_LOCKED. The player regains movement. This prevents the player from silently falling while locked with no inputs. Parry input consumed; no Combat evaluation for the cancelled frame.
- `i_frames_active` remains false during both phases (parry has a Combat-evaluated timing window, not I-frames)
- On expiry (elapsed ≥ `PARRY_DURATION`): return to IDLE or FALLING based on `is_on_floor()`

---

**6. Hit Stun**

Triggered by Combat when a hit is taken while `i_frames_active == false`:
- `velocity.x = 0` for `hit_stun_duration` seconds (base 0.35s from Character Stats)
- `velocity.y` continues under gravity
- On expiry: return to IDLE or FALLING
- **Defensive guard:** If `apply_hit_stun()` is called while `i_frames_active == true`, the call is silently discarded — state and velocity are unchanged. Combat is responsible for not calling `apply_hit_stun()` during I-frames, but Movement defends against incorrect calls.

---

**7. Facing Direction**

`facing: int` = 1 (right) or −1 (left). Updates each physics frame when `velocity.x ≠ 0`: `facing = sign(velocity.x)`. Does not change when velocity.x = 0 (last-direction persistence). Used as the default dodge direction when horizontal input is neutral.

**Facing suppression during DODGING:** `facing` does not update during DODGING — it is snapped to `dodge_dir` at dodge-start and then held for `DODGE_DURATION`. Without this suppression, a backward dodge (dodge_dir opposite to facing) would flip the character's visual orientation mid-roll.

---

**8. Ladder and Rope Climbing**

Climbing state is entered when: a ladder/rope collision area is overlapping AND `move_up` or `move_down` is pressed. This applies from **any movement state** including JUMPING and FALLING — the player can grab a ladder mid-air by pressing into it (MapleStory behavior).

- On grab: `velocity.y` is zeroed and gravity is suspended; `velocity.x` is zeroed
- `velocity.y = -input_y × CLIMB_SPEED` (−1 = up, 1 = down in Godot Y-axis)
- `velocity.x = 0` (no horizontal movement while climbing)
- `CLIMB_SPEED = 80.0 u/s` (tunable)
- Exit: jump **while holding** `move_left` or `move_right` (re-enables gravity, applies JUMP_VELOCITY in the held direction); reaching top/bottom of the ladder region; or pressing `move_left`/`move_right` while at the top of the ladder to step off

---

**9. Drop-Through Platforms**

One-way platforms use a dedicated collision layer (`one_way_platform` layer). Drop-through is triggered when `move_down` is held for ≥ `DROP_THROUGH_HOLD` seconds (0.10s) while `is_on_floor()` is true and the floor collision is from the `one_way_platform` layer.

On trigger: disable collision with `one_way_platform` layer for `DROP_THROUGH_GRACE` seconds (0.20s), then re-enable. The player falls through the platform during this window.

**Grace timer cancellation:** Entering HIT_STUN, DODGING, or PARRY_LOCKED cancels any active `DROP_THROUGH_GRACE` timer immediately, re-enabling the `one_way_platform` collision. This prevents the player from falling through a platform due to taking a hit while a drop-through was in progress.

---

**10. Healing State (HEALING)**

When Health & Death calls `movement.enter_healing()` (player Estus consume confirmed):
- Movement enters HEALING state
- `velocity.x = 0` for the full `HEAL_DURATION`; `velocity.y` continues under gravity (same pattern as PARRY_LOCKED)
- Entry allowed only from: IDLE, RUNNING. Not allowed from: JUMPING, FALLING, DODGING, PARRY_LOCKED, HIT_STUN, DEAD, CLIMBING. If heal action fires from a non-valid state, it is a no-op (H&D is responsible for this guard).
- Internal sub-timer: `heal_elapsed` counts from 0. At `heal_elapsed ≥ HEAL_COMMIT_TIME (0.50s)`: Movement calls `health_death.commit_heal()` — HP restored event fires (owned by H&D, not Movement). **Heal commit check is evaluated BEFORE any incoming `apply_damage()` is processed in the same physics frame** (same-frame ordering rule).
- At `heal_elapsed ≥ HEAL_DURATION (1.0s)`: HEALING → IDLE (if grounded) or FALLING (if airborne); movement resumes.
- **Interrupt rule:** If `apply_hit_stun()` is called while `heal_elapsed < HEAL_COMMIT_TIME`: HEALING is cancelled immediately, Movement transitions to HIT_STUN. The heal charge already spent (in H&D) is not refunded.
- If `apply_hit_stun()` is called while `heal_elapsed ≥ HEAL_COMMIT_TIME`: heal has already committed; Movement transitions to HIT_STUN normally after damage resolves. HP restoration stands.
- `HEAL_COMMIT_TIME` and `HEAL_DURATION` are constants owned by Health & Death GDD; Movement reads them from H&D (not redefined here).
- **Post-commit lock note:** At default values (HEAL_COMMIT_TIME=0.50s, HEAL_DURATION=1.0s), the player is locked for 0.50s after HP is already restored with no reward accumulating. See H&D Tuning Knobs for candidate adjustments (HEAL_DURATION 0.70–0.75s or HEAL_COMMIT_TIME 0.35s).

**Implementation requirement:** Movement must expose a `process_movement(input_x: float, input_y: float, delta: float)` method that accepts externally-supplied input values. `_physics_process` calls `process_movement()` with values from `Input.get_vector()` at runtime; GUT tests call `process_movement()` directly with injected values. This seam is required for deterministic headless testing of all input-dependent ACs (DG-02, PL-01a, PL-01b, CL-01 through CL-04, and all HL ACs).

---

### States and Transitions

| State | velocity.x | velocity.y | i_frames | Available Inputs |
|-------|-----------|-----------|----------|-----------------|
| IDLE | 0 | gravity | false | walk, jump (grounded/coyote), dodge, parry, interact |
| RUNNING | move_speed × direction | gravity | false | jump, dodge, parry, interact |
| JUMPING | player-controlled | upward (decelerating) | false | horizontal movement. **MVP scope: no combat actions (attack, dodge, parry, interact) in air — see Open Question #3** |
| FALLING | player-controlled | gravity | false | horizontal movement. **MVP scope: no combat actions (attack, dodge, parry, interact) in air — see Open Question #3** |
| DODGING | move_speed × 2.2 × dodge_dir | gravity (unchanged) | per window | nothing |
| CLIMBING | 0 | climb_speed × direction | false | jump (exits), interact |
| PARRY_LOCKED | 0 | gravity | false | nothing; floor-loss → FALLING |
| HIT_STUN | 0 | gravity | false | nothing |
| HEALING | 0 | gravity | false | nothing; damage interrupt before `HEAL_COMMIT_TIME` → HIT_STUN |
| DEAD | 0 | 0 | false | nothing |
| SPRINTING | *design pending — see Open Question #5* | gravity | false | *design pending* |

| Event | From States | To State |
|-------|------------|---------|
| Move input pressed | IDLE | RUNNING |
| Move input released | RUNNING | IDLE |
| Jump pressed (valid window) | IDLE, RUNNING | JUMPING |
| Apex reached (velocity.y ≥ 0) | JUMPING | FALLING |
| Land on floor | JUMPING, FALLING | IDLE or RUNNING |
| Dodge granted (InputResolver) | IDLE, RUNNING | DODGING |
| Dodge timer expires | DODGING | IDLE or RUNNING |
| Parry granted (InputResolver) | IDLE, RUNNING | PARRY_LOCKED |
| Parry timer expires | PARRY_LOCKED | IDLE or FALLING |
| Parry floor-loss | PARRY_LOCKED | FALLING (cancel parry) |
| Hit taken (not i_frames) | IDLE, RUNNING, JUMPING, FALLING, PARRY_LOCKED, HEALING | HIT_STUN |
| Hit stun timer expires | HIT_STUN | IDLE or FALLING |
| HP reaches 0 | any | DEAD |
| move_up/down input near ladder | IDLE, RUNNING, JUMPING, FALLING | CLIMBING |
| Jump during climb | CLIMBING | JUMPING |
| Ladder top/bottom reached | CLIMBING | IDLE |
| Drop-through triggered | IDLE, RUNNING (on one-way platform) | FALLING |
| Heal action granted (H&D calls enter_healing()) | IDLE, RUNNING | HEALING |
| Heal complete (heal_elapsed ≥ HEAL_DURATION) | HEALING | IDLE or FALLING |
| Heal interrupted (apply_hit_stun before HEAL_COMMIT_TIME) | HEALING | HIT_STUN |

---

### Interactions with Other Systems

| System | Interface |
|--------|-----------|
| **Input & Controls** | Reads `Input.get_vector()` X/Y components each physics frame; reads `is_action_just_pressed("jump")`; reads `InputResolver.granted_actions` for dodge and parry grants |
| **Character Stats** | Reads `move_speed`, `dodge_iframes`, `dodge_iframes_delay`, `hit_stun_duration` at the start of each relevant action; responds to `stat_changed` signal for live updates |
| **Stamina** | Movement requests dodge execution via `InputResolver`; Stamina's `can_execute("dodge")` gates the grant. Movement does not query Stamina directly. |
| **Combat** | Reads `i_frames_active: bool` and current movement state. Combat calls `apply_hit_stun()` on the Movement component when a non-I-frame hit lands. |
| **Enemy AI** | Reads player `global_position` and `velocity` each physics frame for pathfinding and attack telegraph decisions |
| **Checkpoint & Respawn** | Calls `movement.reset(position)` to teleport and restore default state (IDLE, velocity = ZERO, i_frames = false) after respawn |

## Formulas

All formulas validated by `systems-designer`. I-frame overflow in Formula 4 resolved via runtime clamp. Dodge is ground-only per Detailed Design — no mid-air dodge formula required.

---

### Formula 1 — Jump Apex Height

`apex_height = JUMP_VELOCITY² / (2 × GRAVITY)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Initial vertical velocity | `JUMP_VELOCITY` | Constant | 480.0 u/s | Upward velocity applied at jump start (owned by this GDD) |
| Gravitational acceleration | `GRAVITY` | Constant | 980.0 u/s² | Downward acceleration (owned by this GDD) |
| Apex height | `apex_height` | Derived | ~117.6 u | Max vertical displacement from jump origin |

**Output:** 480² ÷ (2 × 980) = **117.55 units** (~2.1 character heights at 56-unit capsule). Single deterministic value while constants are locked.

**Examples:** Base → 117.55 u | Hypothetical +10% JUMP_VELOCITY buff → 142.2 u

**Level design constraint:** Vertical gap clear-height ≤ 100 units (leaves ~17-unit headroom) to keep jumps feel intentional rather than barely-sufficient.

---

### Formula 2 — Dodge Velocity

`dodge_velocity = move_speed × DODGE_SPEED_MULTIPLIER`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Character movement speed | `move_speed` | Derived stat | 120–160 u/s | From Character Stats GDD (class + DEX scaling) |
| Speed multiplier | `DODGE_SPEED_MULTIPLIER` | Constant | 2.2 | Applied for full DODGE_DURATION (owned by this GDD) |
| Dodge velocity | `dodge_velocity` | Output | 264–352 u/s | Instantaneous horizontal speed during dodge |

**Output range:** Warrior min → 264 u/s; Thief max → 352 u/s; class spread = 88 u/s.

**Examples:** Warrior base (120 u/s) → 264.0 u/s | Thief max (160 u/s) → 352.0 u/s

**Boundary guard:** Assert `DODGE_SPEED_MULTIPLIER ≥ 1.0` — a multiplier < 1.0 would make the dodge slower than walking.

**Buffed move_speed note:** This formula assumes `move_speed ≤ 160 u/s` (the class cap from Character Stats Formula 9). The Character Stats composition rule allows direct `multiplier_total` bonuses on `move_speed` from gear or skills that bypass the class clamp. If `move_speed` exceeds 160 u/s due to a buff, `dodge_velocity` and `dodge_distance` exceed their stated output ranges and can breach the 180-unit barrier constraint. Movement does not enforce a cap on `dodge_velocity`; the Inventory & Equipment GDD and Skills & Abilities GDD must ensure any direct `move_speed` multiplier keeps `dodge_distance` within the Level Design barrier constraint.

---

### Formula 3 — Dodge Distance

`dodge_distance = dodge_velocity × DODGE_DURATION`
`= (move_speed × DODGE_SPEED_MULTIPLIER) × DODGE_DURATION`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Dodge velocity | `dodge_velocity` | Derived | 264–352 u/s | From Formula 2 |
| Dodge animation duration | `DODGE_DURATION` | Constant | 0.45 s | Total dodge (owned by this GDD) |
| Dodge distance | `dodge_distance` | Output | 118.8–158.4 u | Horizontal displacement assuming constant velocity |

**Output range:** Warrior min → 118.8 u (2.12 char heights); Thief max → 158.4 u (2.83 char heights); class spread = 39.6 u.

**Examples:** Warrior base → 118.8 u | Thief max → 158.4 u

**Level design constraint (derived here):** Minimum intended barrier width = **180 units** (158.4 + 21.6-unit margin). Any barrier narrower than 180 units is skippable by a max-speed Thief. This constraint must be cited in the Level Design GDD.

**Barrier constraint formula:** `min_barrier = (max_move_speed × DODGE_SPEED_MULTIPLIER × DODGE_DURATION) + safety_margin`. When either multiplier or duration changes, the Level Design GDD constraint must be recalculated. The current 180-unit barrier is preserved only while `DODGE_SPEED_MULTIPLIER ≤ 2.5` at the current DODGE_DURATION (0.45s): `160 × 2.5 × 0.45 = 180u`. Above 2.5, the barrier is breachable. The documented DODGE_SPEED_MULTIPLIER safe ceiling has been tightened to 2.5 accordingly (see Tuning Knobs).

**Note:** Assumes constant velocity for full DODGE_DURATION. If implementation uses a deceleration curve on recovery frames, actual distance will be 15–25% shorter. Implementation ADR must specify which model is used.

---

### Formula 4 — I-Frame Window

`i_frame_end = min(dodge_iframes_delay + dodge_iframes, DODGE_DURATION)`
`i_frames_active = (elapsed ≥ dodge_iframes_delay) AND (elapsed < i_frame_end)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Time since dodge started | `elapsed` | Runtime float | 0–DODGE_DURATION | Advances each physics frame during dodge |
| I-frame start delay | `dodge_iframes_delay` | Gear-modifiable stat | 0.03–0.15 s | From Character Stats; time before I-frames activate |
| I-frame active duration | `dodge_iframes` | Gear-modifiable stat | 0.10–0.45 s | From Character Stats; raw invulnerability window |
| Dodge animation duration | `DODGE_DURATION` | Constant | 0.45 s | Hard ceiling (owned by this GDD) |
| Effective I-frame end | `i_frame_end` | Derived | ≤ DODGE_DURATION | Clamped so I-frames never outlast the dodge animation |
| I-frames active | `i_frames_active` | Boolean output | true/false | Read by Combat to determine hit immunity |

**Runtime clamp rationale:** `dodge_iframes_delay + dodge_iframes` can exceed DODGE_DURATION at max gear (0.15 + 0.45 = 0.60s > 0.45s). The clamp prevents I-frames from extending past the animation. The stat UI must display the effective clamped window, not the raw `dodge_iframes` value.

**Display formula ownership:** Effective I-frame window for display = `i_frame_end − dodge_iframes_delay`. Inventory & Equipment GDD must use this formula for tooltip rendering (not raw `dodge_iframes`). This formula is defined here; the display logic is owned by Inventory & Equipment GDD.

**Examples:**

| Build | delay | raw_duration | i_frame_end | Active window |
|---|---|---|---|---|
| Base | 0.08s | 0.22s | 0.30s | 0.08s → 0.30s |
| Min stats | 0.03s | 0.10s | 0.13s | 0.03s → 0.13s |
| Max stats (clamped) | 0.15s | 0.45s | **0.45s** | 0.15s → 0.45s (0.30s window) |
| Min delay + max duration (clamped) | 0.03s | 0.45s | **0.45s** | 0.03s → 0.45s (0.42s window) |

**Boundary guards:** Assert `dodge_iframes_delay ≥ 0`; assert `dodge_iframes > 0`; assert `DODGE_DURATION > 0`.

---

### Formula 5 — Jump Air Time

`air_time = 2 × JUMP_VELOCITY / GRAVITY`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Initial vertical velocity | `JUMP_VELOCITY` | Constant | 480.0 u/s | Upward velocity at jump start |
| Gravitational acceleration | `GRAVITY` | Constant | 980.0 u/s² | Downward pull |
| Total air time | `air_time` | Derived | ~0.98 s | Time from jump to landing on flat ground |

**Output:** 2 × 480 / 980 = **0.9796s** (~0.98s). Assumes landing at same height as jump origin. Falls below origin extend air time asymmetrically under continued gravity.

**Examples:** Base → 0.98s | Hypothetical +10% JUMP_VELOCITY → 1.08s

**Level design note:** Descent from elevated ledges continues beyond 0.98s. Size drop-down gaps using fall time, not jump air time.

## Edge Cases

- **If `is_on_floor()` returns true on the same frame the player presses jump**: Jump fires immediately. No delay. Both conditions are evaluated inside `_physics_process()` and the jump takes priority over gravity suppression.

- **If the player walks off a ledge without pressing jump**: Coyote window activates. `COYOTE_JUMP_FRAMES = 4` frames from the moment `is_on_floor()` first returns false. If jump is pressed within those 4 frames, jump fires normally. If the window expires, the player is in FALLING state and cannot jump until landing.

- **If the player presses jump while in FALLING state (coyote window expired)**: No-op. Jump is discarded. Jump uses direct polling, not the input buffer — there is no buffered jump. This is intentional: the coyote window is the sole leniency mechanism for ledge-timing misses. A player who presses jump after the window has expired must land before jumping again.

- **If the player is in DODGING state and takes a hit**: If `i_frames_active == true`, the hit is ignored. If `i_frames_active == false` (outside the I-frame window), the hit is applied: Movement transitions to HIT_STUN immediately and remaining dodge velocity is cancelled.

- **If the player presses dodge in PARRY_LOCKED state**: Suppressed — PARRY_LOCKED is not a valid origin for DODGING. The input may be buffered by InputResolver but Stamina will not grant it while PARRY_LOCKED is active. Movement does not transition.

- **If `move_speed` changes via `stat_changed` signal mid-dodge**: No effect on the current dodge. `dodge_velocity` is locked at the value computed at dodge-start. The new stat takes effect on the next walk or dodge.

- **If `dodge_iframes_delay` or `dodge_iframes` change via `stat_changed` mid-dodge**: Same — I-frame timing is locked at the values read at dodge-start. `stat_changed` during a dodge is a no-op until the next dodge begins.

- **If `move_speed` changes via `stat_changed` while walking**: Takes effect immediately on the next physics frame. Walk speed updates without interruption.

- **If the player presses `move_down` on a solid (non-one-way) floor**: No drop-through. The trigger only fires when the floor collision is tagged `one_way_platform`.

- **If the player releases `move_down` before the `DROP_THROUGH_HOLD` threshold (0.10s)**: The hold timer resets. The player must hold for the full 0.10s continuously to trigger drop-through.

- **If the player presses `move_up` or `move_down` while JUMPING or FALLING near a ladder**: CLIMBING state is entered immediately — velocity is zeroed and gravity is suspended. The player grabs the ladder mid-air (MapleStory behavior). No requirement to be grounded first.

- **If the player presses jump while in CLIMBING state with no horizontal input**: No-op. The player remains on the ladder. Jump only exits the ladder when `move_left` or `move_right` is also held at the moment jump is pressed.

- **If the player is in JUMPING state (ascending) with `move_up` held while overlapping a ladder**: CLIMBING state is entered immediately — velocity is zeroed and gravity is suspended, identical to the FALLING case. Upward momentum does not prevent a ladder grab. This matches MapleStory behavior and is intentional.

- **If the player presses jump while in CLIMBING state while holding `move_left` or `move_right`**: Jump exits the ladder: gravity re-activates, `velocity.y = -JUMP_VELOCITY`, `velocity.x = facing × move_speed`, state transitions to JUMPING. The ladder collision is suppressed for `LADDER_REGRAB_SUPPRESS_FRAMES` (4 frames, 67ms; tunable independently of `COYOTE_JUMP_FRAMES`) to prevent immediate re-grab.

- **If both `move_up` and `move_down` are pressed simultaneously in CLIMBING**: Net vertical velocity = 0. Player clings to ladder without moving.

- **If HP reaches 0 while in DODGING with `i_frames_active == true`**: DEAD state is entered immediately regardless of I-frame status. I-frames prevent damage from individual hits; they do not prevent death from HP-zero transitions triggered by prior accumulated damage. `i_frames_active` is set false on DEAD entry.

## Dependencies

**Upstream (this system depends on):**

| System | What we need | Interface |
|--------|-------------|-----------|
| **Input & Controls** | `Input.get_vector("move_left","move_right","move_up","move_down")` snapped vector; `is_action_just_pressed("jump")`; `InputResolver.granted_actions` for dodge and parry grants | Polled each physics frame |
| **Character Stats** | `move_speed`, `dodge_iframes`, `dodge_iframes_delay`, `hit_stun_duration` | Read at action-start; updated via `stat_changed` signal |

**Downstream (these systems depend on Movement):**

| System | What they need from Movement | Interface |
|--------|------------------------------|-----------|
| **Combat** | `i_frames_active: bool` (per-frame); current movement state; `apply_hit_stun(duration)` call to enter HIT_STUN | Signal or direct call |
| **Enemy AI** | Player `global_position` and `velocity` each physics frame | Read-only access to player node |
| **Stamina** | Queried by `InputResolver` before granting dodge/parry; Movement does not call Stamina directly | InputResolver mediates |
| **Checkpoint & Respawn** | `movement.reset(position: Vector2)` — teleports and restores state to IDLE | Direct call |
| **Health & Death** | Calls `movement.enter_healing()` to begin HEALING state; calls `movement.apply_hit_stun()` when damage interrupts a heal before HEAL_COMMIT_TIME | Direct call |
| **Tutorial & Onboarding** | Current movement state for first-use detection (e.g., "first dodge", "first jump") | Read-only |
| **Companion AI** | Player position and movement state for AI decision-making | Read-only |

**Cross-document coordination required:**
- **Combat GDD** must confirm it reads `i_frames_active` from Movement (not its own calculation) and calls `movement.apply_hit_stun()` when a non-I-frame hit lands
- **Stamina GDD** must confirm it does not directly query Movement state — permission gating happens through `InputResolver`
- **Level Design GDD** must acknowledge the **180-unit minimum barrier width** constraint derived from Formula 3 (max Thief dodge distance) and the **100-unit max clear-height** constraint derived from Formula 1
- **Enemy AI GDD** must confirm it reads player position from the player node's `global_position` property, not a separate position cache
- **Inventory & Equipment GDD** must note that `dodge_iframes` and `dodge_iframes_delay` are gear-modifiable stats whose combined value is clamped at runtime to DODGE_DURATION (Formula 4 runtime clamp) — the UI must display the effective clamped window

## Tuning Knobs

| Knob | Location | Current Value | Safe Range | Too High → | Too Low → |
|------|----------|---------------|-----------|------------|-----------|
| `GRAVITY` | Formula 1, 5 | 980.0 u/s² | 600–1400 | Jump arcs feel floaty and disconnected from combat timing; harder to read enemy attacks | Jump barely leaves the ground; platforming becomes extremely snappy; enemies with vertical attacks trivialize the mechanic |
| `JUMP_VELOCITY` | Formula 1, 5 | 480.0 u/s | 300–529 | Character sails over enemies; aerial positioning trivializes most encounters | Jump barely clears enemy hitboxes; feels heavy and punishing on platforming. **⚠ Safe ceiling reduced from 650 to 529: at GRAVITY=1400 (safe ceiling), JUMP_VELOCITY² / (2×1400) ≤ 100u requires JUMP_VELOCITY ≤ 529 u/s. JUMP_VELOCITY and GRAVITY must satisfy `GRAVITY ≥ JUMP_VELOCITY² / 200` to preserve the 100-unit level design constraint.** |
| `TERMINAL_VELOCITY` | §2 Gravity | 1200.0 u/s | 800–2000 | Falls in normal geometry hit the cap; physics feel unnaturally bounded | Not applicable — this is a safety net, not a design lever; removing it risks Jolt tunneling |
| `COYOTE_JUMP_FRAMES` | §3 Jump | 4 frames (67 ms) | 2–8 | Coyote window large enough that "walking off a ledge" and "jumping from a ledge" feel identical; skill ceiling for ledge-jump timing disappears | Jump misses too frequently on ledge edges; players feel the controls are unresponsive |
| `PARRY_RECOVERY` | §5 Parry Lock | 0.15s | 0.05–0.40 | Failed parry leaves the player locked so long that an enemy second attack always connects; parrying feels too punishing to attempt | Failed parry has negligible commitment cost; players spam parry on every enemy attack with no downside |
| `LADDER_REGRAB_SUPPRESS_FRAMES` | §8 Climbing | 4 frames (67 ms) | 2–8 | Long suppression window causes momentary unresponsiveness when jumping off a ladder near another ladder | Player immediately re-grabs the same ladder after a climb-jump exit; directional escapes are impossible |
| `DODGE_DURATION` | §4 Dodge, Formula 3 | 0.45 s | 0.30–0.65 | Dodge animation is long enough that the player is committed for too much of a combat cycle; recovery frames feel punishing | Dodge is too short to register as a distinct action; blurs the line between walking and dodging |
| `DODGE_SPEED_MULTIPLIER` | §4 Dodge, Formula 2 | 2.2 | 1.5–2.5 | Dodge covers so much ground it skips geometry and trivializes attack arcs. **⚠ Safe ceiling reduced from 3.0 to 2.5: above 2.5 at current DODGE_DURATION (0.45s), max Thief dodge distance exceeds the 180-unit barrier constraint (160 × 2.5 × 0.45 = 180u exactly). Combined max-safe DODGE_SPEED_MULTIPLIER × DODGE_DURATION must satisfy ≤ 1.125 to preserve the barrier.** | Dodge barely faster than walking; the burst speed that makes dodge feel decisive is lost |
| `CLIMB_SPEED` | §8 Climbing | 80.0 u/s | 50–140 | Climbing feels instant; ladder sections feel trivial | Climbing feels like swimming in syrup; enemies can easily reach and hit a climbing player |
| `DROP_THROUGH_HOLD` | §9 Drop-through | 0.10 s | 0.05–0.25 | Long hold requirement makes drop-through feel unresponsive | Accidental drops happen when the player merely taps down near a one-way platform |
| `DROP_THROUGH_GRACE` | §9 Drop-through | 0.20 s | 0.10–0.40 | Player can fall through multiple stacked one-way platforms in a single input | Player immediately re-lands on the same platform they tried to drop through |

**Interaction warnings:**
- `GRAVITY` + `JUMP_VELOCITY` must be tuned together — changing one without the other shifts apex height and air time simultaneously (Formulas 1 and 5). The level design constraints (100-unit vertical gap max) assume their current ratio.
- `DODGE_DURATION` + `DODGE_SPEED_MULTIPLIER` determine `dodge_distance` (Formula 3). The combined constraint is `DODGE_SPEED_MULTIPLIER × DODGE_DURATION ≤ 1.125` to preserve the 180-unit barrier at max Thief speed. Raising DODGE_DURATION beyond 0.45s requires lowering DODGE_SPEED_MULTIPLIER ceiling proportionally, and vice versa. Always recalculate `min_barrier = max_move_speed × DODGE_SPEED_MULTIPLIER × DODGE_DURATION + 21.6` and update the Level Design GDD.
- `DODGE_DURATION` is the hard ceiling for the I-frame window (Formula 4 runtime clamp). Reducing DODGE_DURATION tightens the maximum achievable I-frame window for high-gear builds.
- `PARRY_RECOVERY` is a constant and does not scale with gear. Tuning `parry_window` via gear affects only the success window duration; recovery commitment remains fixed. Do not conflate the two when designing parry gear.

## Visual/Audio Requirements

Movement has no direct visual output of its own — all combat feedback (I-frame flash, hit stun reaction, parry lock stance) belongs to Combat and Animation GDDs. However, Movement owns the state machine that drives animation state transitions, so the following events must have corresponding animation hooks:

| Event | Animation Hook | Notes |
|-------|---------------|-------|
| IDLE → RUNNING | Trigger `run` animation | Loop until IDLE |
| RUNNING → IDLE | Trigger `idle` animation | |
| IDLE/RUNNING → JUMPING | Trigger `jump_ascent` animation | |
| JUMPING → FALLING | Trigger `jump_fall` animation | |
| FALLING → IDLE | Trigger `land` animation | Short non-interruptible |
| IDLE/RUNNING → DODGING | Trigger `dodge_roll` animation | Duration = DODGE_DURATION |
| IDLE/RUNNING → PARRY_LOCKED | Trigger `parry_stance` animation | Duration = PARRY_DURATION |
| Any → HIT_STUN | Trigger `hit_stun` animation | |
| Any → DEAD | Trigger `death` animation | |
| Any → CLIMBING | Trigger `climb` animation | Loop while climbing |
| IDLE/RUNNING → HEALING | Trigger `heal_use` animation (flask raised) | Duration = HEAL_DURATION (1.0s). Commit point at HEAL_COMMIT_TIME (0.50s) must be visually readable. Owned by Animation/Art GDD; details deferred to `/asset-spec system:movement`. |

**Sound hooks** (owned by Audio Design GDD, triggered by Movement state events):
- Landing after a jump: footstep/land sound (scaled by fall height — short fall vs. long fall)
- Dodge roll start: whoosh/roll sound
- Ladder grab (entering CLIMBING from airborne): grab sound

> **📌 Asset Spec note:** Run `/asset-spec system:movement` after the Art Bible is approved to generate per-animation frame counts, sprite sheet specs, and visual descriptions from this section.

## UI Requirements

Movement has no dedicated UI screen. The HUD GDD owns stamina bars and status indicators. The only UI surface this system touches is the stat screen's display of gear-modified `dodge_iframes` and `dodge_iframes_delay` — the effective clamped I-frame window (Formula 4 runtime clamp) must be displayed, not the raw stat values. Owner: HUD GDD / Inventory & Equipment GDD.

## Acceptance Criteria

*Story Type: Logic — all criteria require passing automated unit tests in `tests/unit/movement/` before any implementing story is marked Done.*

### Walking

**WK-01** — GIVEN `move_speed = 120` and `move_left` is pressed, WHEN `_physics_process` runs, THEN `velocity.x = -120`.

**WK-02** — GIVEN the player is walking (`velocity.x ≠ 0`), WHEN horizontal input is released, THEN `velocity.x = 0` on the next physics frame.

**WK-03** — GIVEN `move_speed` changes via `stat_changed` to 150, WHEN the next `_physics_process` runs with horizontal input active, THEN `abs(velocity.x) = 150`.

### Jump

**JM-01** — GIVEN `is_on_floor() = true`, WHEN `jump` is pressed, THEN `velocity.y = -480`.

**JM-02** — GIVEN the player is in FALLING state with `coyote_frames_remaining > 0`, WHEN `jump` is pressed, THEN `velocity.y = -480`.

**JM-03** — GIVEN the player is in FALLING state with `coyote_frames_remaining = 0`, WHEN `jump` is pressed, THEN `velocity.y` is unchanged (no jump fires).

**JM-04** — GIVEN the player is already airborne (JUMPING or FALLING) with no coyote window, WHEN `jump` is pressed, THEN `velocity.y` is unchanged (no double jump).

**JM-05** — GIVEN `coyote_frames_remaining = 1`, WHEN `jump` is pressed on that exact frame, THEN `velocity.y = -480` (last valid coyote frame fires).

**JM-06** — GIVEN `coyote_frames_remaining` has just decremented to 0 (window expired), WHEN `jump` is pressed, THEN `velocity.y` is unchanged.

### Jump Physics (Formulas 1 and 5)

**AP-01** — GIVEN `JUMP_VELOCITY = 480` and `GRAVITY = 980`, WHEN a jump is simulated tick-by-tick until `velocity.y ≥ 0` (apex reached), THEN total vertical displacement is ≥ 117.0 u AND ≤ 118.1 u (within ±0.5% of the formula result of 117.55 u).

**AP-02** — GIVEN a jump from floor height, WHEN the character returns to floor height, THEN elapsed time is ≥ 0.97s AND ≤ 0.99s (within ±0.5% of the formula result of 0.98s).

### Dodge Roll

**DG-01** — GIVEN `move_speed = 120`, no directional input, and `facing = 1`, WHEN dodge is granted by `InputResolver`, THEN `velocity.x = 264.0` (120 × 2.2).

**DG-02** — GIVEN a dodge is active (elapsed = 0.20s) with `dodge_dir = 1` (rightward), WHEN `input_x = -1` is injected into `_physics_process`, THEN `velocity.x` equals the rightward dodge velocity set at t=0 (dodge is not redirectable). *Requires Movement to expose a `process_movement(input_x, input_y, delta)` seam or equivalent input injection for headless GUT testing.*

**DG-03** — GIVEN a dodge started at t=0, WHEN elapsed = 0.46s, THEN movement state is no longer DODGING.

**DG-04** — GIVEN the player is in JUMPING state, WHEN dodge is granted by `InputResolver`, THEN dodge is not executed and movement state remains JUMPING.

**DG-05** — GIVEN `move_speed = 120` and `DODGE_DURATION = 0.45s`, WHEN a full dodge completes and total horizontal displacement is measured, THEN displacement is ≥ 117.6 u AND ≤ 120.0 u (within ±1% of 118.8 u).

### I-Frame Window (Formula 4)

**IF-01** — GIVEN dodge starts at t=0 with `dodge_iframes_delay = 0.08s` and `dodge_iframes = 0.22s`, WHEN `elapsed = 0.07s`, THEN `i_frames_active = false`.

**IF-02** — GIVEN the same dodge, WHEN `elapsed = 0.08s`, THEN `i_frames_active = true`.

**IF-03** — GIVEN the same dodge, WHEN `elapsed = 0.30s`, THEN `i_frames_active = false`.

**IF-04** — GIVEN `delay = 0.15s` and `duration = 0.45s` (overflow case, clamped end = 0.45s), WHEN `elapsed = 0.44s`, THEN `i_frames_active = true` (0.44 < 0.45).

**IF-05** — GIVEN the same overflow case, WHEN elapsed reaches `DODGE_DURATION` (0.45s) and the dodge ends, THEN `i_frames_active = false` and state is no longer DODGING.

### Parry Lock

**PL-01a** — GIVEN parry is triggered (elapsed = 0.10s, within success phase), WHEN horizontal input is injected into `_physics_process`, THEN `velocity.x = 0`.

**PL-01b** — GIVEN parry is triggered (elapsed = 0.40s, within `PARRY_RECOVERY` phase, past `parry_window = 0.35s`), WHEN horizontal input is injected into `_physics_process`, THEN `velocity.x = 0` (player remains movement-locked during recovery).

**PL-02** — GIVEN parry lock active (base values: `PARRY_DURATION = 0.50s`), WHEN `elapsed = 0.51s`, THEN state is no longer PARRY_LOCKED and horizontal input resumes normal movement.

**PL-03** — GIVEN the player is in JUMPING or FALLING state (airborne, `is_on_floor() = false`), WHEN a parry grant is injected via `InputResolver`, THEN Movement state does NOT transition to PARRY_LOCKED and state remains JUMPING or FALLING respectively (parry is grounded-only).

**PL-04** — GIVEN the player is in PARRY_LOCKED state, WHEN `is_on_floor()` returns `false` during `_physics_process` (floor lost mid-animation), THEN Movement transitions to FALLING immediately and PARRY_LOCKED is cancelled.

### Hit Stun

**HS-01** — GIVEN the player is in RUNNING state, WHEN `apply_hit_stun(0.35)` is called, THEN `velocity.x = 0` and state = HIT_STUN.

**HS-02** — GIVEN HIT_STUN state with `hit_stun_duration = 0.35s`, WHEN `elapsed = 0.36s`, THEN state is no longer HIT_STUN.

**HS-03** — GIVEN `i_frames_active = true`, WHEN `apply_hit_stun()` is called on the Movement component, THEN state does not change to HIT_STUN and `velocity.x` is unchanged. (Verifies the defensive guard specified in §6 — the call is silently discarded.)

### Facing Direction

**FC-01** — GIVEN `facing = 1`, WHEN `velocity.x = -120`, THEN `facing = -1`.

**FC-02** — GIVEN `facing = 1` and the player stops walking, WHEN `velocity.x = 0`, THEN `facing` remains 1.

### Ladder Climbing

**CL-01** — GIVEN the player is in FALLING state near a ladder, WHEN `move_up` is pressed, THEN state = CLIMBING AND `velocity.y = 0` on the transition frame.

**CL-01b** — GIVEN CLIMBING state with no vertical input, WHEN `_physics_process` runs, THEN `velocity.y = 0` (gravity does not accumulate while climbing).

**CL-02** — GIVEN CLIMBING state and `move_up` is pressed, WHEN `_physics_process` runs, THEN `velocity.y = -CLIMB_SPEED` (upward).

**CL-03** — GIVEN CLIMBING state with no horizontal input, WHEN `jump` is pressed, THEN state remains CLIMBING and `velocity.y` is unchanged.

**CL-04** — GIVEN CLIMBING state with `move_right` held (facing = 1), WHEN `jump` is pressed, THEN state = JUMPING AND `velocity.y = -480` AND `velocity.x = facing × move_speed` (horizontal velocity restored on ladder exit, per §8).

### Healing State

*Timer-dependent tests (marked ⏱) must use `delta = 1/60.0` per tick via `process_movement()` injection — not wall-clock time.*

**HL-01** — GIVEN the player is in IDLE or RUNNING state, WHEN `movement.enter_healing()` is called, THEN state = HEALING AND `velocity.x = 0` on the transition frame.

**HL-02** — GIVEN HEALING state is active, WHEN horizontal input is injected via `process_movement(input_x=1.0, ...)`, THEN `velocity.x = 0` (movement locked regardless of input).

**HL-03** ⏱ — GIVEN HEALING state is active and `heal_elapsed < HEAL_COMMIT_TIME (0.50s)` (advance timer via mock to 0.49s), WHEN `apply_hit_stun(0.35)` is called, THEN Movement transitions to HIT_STUN immediately and HEALING is cancelled.

**HL-04** ⏱ — GIVEN HEALING state is active and `heal_elapsed ≥ HEAL_COMMIT_TIME (0.50s)` (advance timer to 0.51s), WHEN `apply_hit_stun(0.35)` is called, THEN Movement transitions to HIT_STUN normally (heal already committed — damage resolves on top).

**HL-05** ⏱ — GIVEN HEALING state is active, WHEN `heal_elapsed ≥ HEAL_DURATION (1.0s)` (advance timer past 1.0s), THEN state transitions to IDLE (if `is_on_floor() = true`) or FALLING (if `is_on_floor() = false`) and horizontal input resumes.

**HL-06** — GIVEN HEALING state is active with `is_on_floor() = false` and `velocity.y = 0.0` at start, WHEN `_physics_process(delta)` is called twice with `delta = 1/60.0`, THEN `velocity.y` after frame 2 > `velocity.y` after frame 1 > 0 (gravity accumulates normally during HEALING).

### Drop-Through Platforms

**DT-01** — GIVEN the player is on a `one_way_platform` floor, WHEN `move_down` has been held for N frames totalling ≥ 0.10s (e.g., 6 frames at 16.67ms each = 100ms), THEN the `one_way_platform` collision layer is disabled.

**DT-02** — GIVEN `move_down` held for 0.08s on a `one_way_platform`, WHEN `move_down` is released, THEN drop-through does not trigger and the hold timer resets to 0.

**DT-03** — GIVEN drop-through was triggered at t=0 (collision disabled), WHEN `elapsed = 0.19s`, THEN `one_way_platform` collision layer remains disabled.

**DT-04** — GIVEN the same drop-through, WHEN `elapsed = 0.21s`, THEN `one_way_platform` collision layer is re-enabled.

## Open Questions

1. **Dodge velocity curve** — Should `dodge_velocity` be constant for the full DODGE_DURATION (current spec), or ease-out on recovery frames? Constant is simpler but may feel robotic; a curve is more natural but changes the effective `dodge_distance` below Formula 3's value by 15–25%. Owner: Gameplay feel — resolve during first dodge-roll animation pass.

2. **Prototype SPEED discrepancy** — Prototype uses `SPEED = 250.0 u/s` while Character Stats defines `move_speed = 120–160 u/s`. Production Movement must use the Character Stats values. Verify the prototype's higher speed was a placeholder and that 120–160 feels correct in a Godot unit-to-pixel ratio context. Owner: First playtest of the production build.

3. **Aerial combat actions (MVP scope decision)** — Attack and parry are not available from JUMPING or FALLING in MVP. This is a deliberate MVP scope call: keeping air states simple reduces combat complexity before the core grounded loop is validated. Post-MVP: re-evaluate whether aerial attack or parry should be added based on Pillar 4 ("Motion Is the Answer") and Pillar 1 ("combat is learnable rhythm") after the grounded combat loop is prototyped. Owner: Combat GDD authoring session.

4. **Ladder grab range** — How far from a ladder must the player be to grab it mid-air? Current spec says "ladder collision area is overlapping." The exact hitbox size of the ladder collision area is an implementation decision. Owner: Level Design GDD / level designer during prototype of first ladder room.

5. ~~**Sprint / dash**~~ — **RESOLVED**: Universal sprint is a Movement GDD mechanic (all classes). The circular deferral between this GDD and Input & Controls is closed. **Pending design work before implementation:** sprint rule (speed multiplier, stamina cost, duration or continuous hold), sprint formula, sprint state or modifier on RUNNING, and acceptance criteria must be authored in a dedicated design session. A `sprint` action binding must also be added to the Input & Controls GDD. Owner: Next systems-design session before Movement stories are picked up.
