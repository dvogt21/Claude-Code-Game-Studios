# Input & Controls

> **Status**: Revised (post design-review 2026-05-31)
> **Author**: Design session + agents
> **Last Updated**: 2026-05-31
> **Implements Pillar**: Pillar 1 (Read the Rhythm), Pillar 4 (Motion Is the Answer)
> **Layer**: Foundation | **Priority**: MVP | **Design Order**: #2

## Overview

Input & Controls is the action map — the authoritative, named registry of every player input that Ashen Maple recognizes, bound to both keyboard/mouse and gamepad, and queryable by any system that responds to player intent. At the infrastructure level, this system defines the complete action vocabulary: `move_left/right/up/down`, `attack`, `dodge`, `parry`, `jump`, `interact`, `pause`, `skill_1`, `skill_2`, `companion_command`, and the UI navigation family (`ui_confirm`, `ui_cancel`, `ui_navigate`). Every downstream system — Movement, Stamina, Combat, Menus & Navigation — reads from named actions defined here, never from raw keycodes or button IDs. Rebinding is therefore free: any input can be remapped by the player without touching a single line of game logic.

At the player-facing level, Input & Controls is the invisible system that determines whether Ashen Maple *responds* to you or *ignores* you. A parry that registers on the exact frame the player presses the button feels like mastery. A parry that silently drops input once every thirty attempts feels like the game cheating. This system owns the input polling model, the action priority ordering (when multiple actions share a frame), and the input buffer window — a 1–3 frame buffer that prevents a parry input pressed one frame too early from being silently discarded. These decisions propagate directly into every system that reads input, making Input & Controls one of the most impactful systems in the game despite being invisible during play.

## Player Fantasy

Input & Controls has no direct player fantasy of its own. Players do not think "I love this game's input mapping" — they think "parrying feels precise" or "dodging feels instant." The fantasy those experiences deliver belongs to Combat (parry timing, stagger) and Movement (dodge feel, repositioning). This system's success is measured by its absence from the player's conscious experience: if a player ever blames the controls, this system has failed. If a player never thinks about controls at all — only about the enemies they're reading and the openings they're exploiting — this system has succeeded.

The one player-perceivable output of this system is **rebinding support**: a player who switches from gamepad to keyboard/mouse, or who needs an accessible layout, should be able to reconfigure any action without friction. That is the only moment the player interacts with this system directly.

## Detailed Design

### Core Rules

**1. Action Map — Complete Action Vocabulary**

All systems read from named actions defined in this system's `InputMap` — never from raw keycodes, joypad button IDs, or axis indices. Rebinding any action requires only changing the mapping here; no game logic changes.

**Gameplay actions** (active in `MODE_GAMEPLAY`):

| Action | Description | Default Gamepad | Default KB/Mouse |
|--------|-------------|----------------|-----------------|
| `move_left` | Move left — one of four directional components fed to `Input.get_vector()` | L-stick left / D-pad left | A / Left arrow |
| `move_right` | Move right | L-stick right / D-pad right | D / Right arrow |
| `move_up` | Move up | L-stick up / D-pad up | W / Up arrow |
| `move_down` | Move down | L-stick down / D-pad down | S / Down arrow |
| `attack` | Primary attack | Square (PS) / X (Xbox) | J / Left click |
| `dodge` | Dodge roll (grants I-frames) | Circle (PS) / B (Xbox) | Left Shift |
| `parry` | Shield parry (timing window) | L1 (PS) / LB (Xbox) | Q / Right click |
| `jump` | Jump | Cross (PS) / A (Xbox) | Space |
| `interact` | Interact with NPCs / objects | Triangle (PS) / Y (Xbox) | E |
| `pause` | Open pause menu | Options (PS) / Menu (Xbox) | Escape |
| `skill_1` | Class skill slot 1 — **TBD; binding reserved for Skills & Abilities GDD** | TBD | TBD |
| `skill_2` | Class skill slot 2 — **TBD; binding reserved for Skills & Abilities GDD** | TBD | TBD |
| `companion_command` | Issue command to active companion — **TBD; binding reserved for Companion AI GDD** | TBD | TBD |

> **Scope note — sprint:** If sprint is a class ability (e.g., Thief dash), it belongs in the Skills & Abilities GDD as `skill_1` or a dedicated skill slot. If sprint is a universal movement modifier for all classes, it must be added here as a named action before the Movement GDD is authored. Resolve during Movement GDD design.

> **Scope note — `move_left/right/up/down`:** These four actions replace a single `move` action. `Input.get_vector("move_left", "move_right", "move_up", "move_down")` requires four separate InputMap entries; there is no composite action type in Godot 4's InputMap.

**UI navigation actions** (active in `MODE_UI` and `MODE_CUTSCENE` where noted):

| Action | Description | Default Gamepad | Default KB/Mouse |
|--------|-------------|----------------|-----------------|
| `ui_up / ui_down / ui_left / ui_right` | Directional navigation | D-pad / L-stick | Arrow keys / WASD |
| `ui_confirm` | Confirm / select | Cross (PS) / A (Xbox) | Enter / Space |
| `ui_cancel` | Cancel / back | Circle (PS) / B (Xbox) | Escape / Backspace |
| `ui_tab_next` | Next tab (stat screen, inventory) | R1 (PS) / RB (Xbox) | Tab |
| `ui_tab_prev` | Previous tab | L1 (PS) / LB (Xbox) | Shift+Tab |

Note: `pause` is active in all modes. `ui_confirm` is the only active action in `MODE_CUTSCENE`. `L1` serves as `parry` in gameplay and `ui_tab_prev` in UI mode — no conflict because only one mode's actions are active at a time.

---

**2. Input Polling Model**

Input handling is split into two stages to guarantee frame-accurate capture:

**Stage 1 — Buffer writes (in `_input(event)`):** `_input()` is called synchronously by Godot when an input event arrives — not on a physics timer. When `event.is_action_pressed(action)` returns `true` for a bufferable action (`attack`, `dodge`, `parry`), the buffer records `press_frame[action] = Engine.get_physics_frames()`. Using `_input()` for writes prevents inputs from being silently dropped between physics ticks — the failure mode of polling `is_action_just_pressed()` inside `_physics_process()`.

**Stage 2 — Queries and continuous polling (in `_physics_process()`):** The `InputResolver` node (see §2a below) runs each physics frame. Continuous movement is read here:

- **`Input.get_vector("move_left", "move_right", "move_up", "move_down")`**: Returns the raw analog vector before 8-directional snapping. Requires the four separate InputMap actions defined in §1.
- **`Input.is_action_pressed(action)`**: Returns `true` while held. Used for: movement axes (continuous intent).
- **`Input.is_action_just_pressed(action)`**: Used only for non-bufferable actions (`jump`, `interact`) where single-frame polling is acceptable because these actions are not timing-critical relative to the combat loop.

UI inputs are handled by Godot's built-in Control node focus system via the `_gui_input()` callback and `gui_input` signal — event-driven, not polled. This keeps UI navigation decoupled from the physics tick. (`_unhandled_input()` is for non-UI nodes; Control nodes use `_gui_input()`.)

---

**§2a. InputResolver Node**

The `InputResolver` is a singleton (Autoload) that runs once per physics frame inside `_physics_process()`. It enforces the Stamina/Combat permission contract and is the **sole owner of buffer consumption**:

1. For each bufferable action (`attack`, `dodge`, `parry`), query `was_action_buffered(action, current_frame)`.
2. For each buffered action, query Stamina: `stamina_system.can_execute(action)` → returns `bool`.
3. Produce `granted_actions: Array[String]` — actions that are both buffered and stamina-approved.
4. Expose `granted_actions` to Combat. Combat reads only from this list, never from `was_action_buffered()` directly.
5. For each action in `granted_actions` that Combat executes, `InputResolver` calls `consume_buffer(action)`.

This guarantees Stamina evaluation always precedes Combat execution regardless of scene tree order. Systems other than Combat may call `was_action_buffered()` passively (e.g., Tutorial & Onboarding) but must never call `consume_buffer()` directly.

---

**3. Digital 8-Directional Movement**

`Input.get_vector("move_left", "move_right", "move_up", "move_down")` produces a raw analog vector, which is then snapped to one of nine outputs: `Vector2.ZERO` or one of the 8 cardinal/diagonal unit vectors.

Algorithm (executed each physics frame):
1. Read raw analog vector from `Input.get_vector()` (stick, D-pad, or four digital keys)
2. If `magnitude < 0.20` (deadzone): output `Vector2.ZERO`
3. Else: snap to nearest 45° angle → output the corresponding unit vector (one of 8 directions at magnitude 1.0)

Keyboard produces unit vectors directly via `get_vector()`: W = (0, −1), S = (0, 1), A = (−1, 0), D = (1, 0). Diagonal combinations (e.g., W+D → raw `(1, −1)`) are normalized before snapping — `atan2` is scale-invariant, so normalization happens implicitly in the angle computation.

There is no half-speed movement. All movement is either stopped or full-speed. **Design rationale:** committed directional inputs enforce the positional decision-making that Pillar 4 (Motion Is the Answer) demands — every movement is a declared direction, not a variable hedge. Analog speed ramping would also create a parity gap between gamepad and keyboard/mouse on a PC-first title.

---

**4. Input Buffer Window**

An input buffer prevents timing-sensitive actions from being silently discarded when they arrive 1–3 frames before the game enters a valid state for that action.

**Bufferable actions**: `attack`, `dodge`, `parry` (combat actions with narrow timing interactions).
**Non-bufferable**: movement axes (`move_left`, `move_right`, `move_up`, `move_down`), `jump`, `interact`, all `ui_*` actions.

Buffer mechanism: When `_input(event)` receives a just-pressed event for a bufferable action, record the physics frame timestamp (`Engine.get_physics_frames()`). When `InputResolver` queries "was this action pressed?", it checks: *was the action pressed within the last `INPUT_BUFFER_FRAMES` physics frames?* If yes, the action is eligible for the granted-actions list.

`INPUT_BUFFER_FRAMES = 3` (tunable constant; 3 frames = 50 ms at 60 fps).

Buffer consumption: The `InputResolver` (§2a) is the sole consumer. Once `InputResolver` grants an action and Combat executes it, `InputResolver` calls `consume_buffer(action)` — clearing the press. A buffered press cannot be consumed twice. A new press on the same action overwrites the existing buffer entry.

---

**5. Action Priority — Same-Frame Conflict Resolution**

If multiple **bufferable** actions (`attack`, `dodge`, `parry`) have pending presses on the same frame, resolve in this order:

1. `parry` — defensive intent is never overridden by offensive input
2. `dodge` — evasion over attack
3. `attack` — offensive

`jump` and `interact` are non-bufferable — they are handled by direct `is_action_just_pressed()` polling and do not participate in this priority resolution. `jump` and `attack` pressed simultaneously: each is handled by its own path — `attack` goes through the buffer, `jump` is polled directly; there is no conflict.

Movement axes (`move_left`, `move_right`, `move_up`, `move_down`) are always active and do not conflict with any action. Only one priority winner is consumed per frame.

---

**6. Input Mode Stack**

The stack manages which actions are currently active. Each push suspends the previous context; each pop restores it.

| Mode | Active Actions | Suppressed |
|------|----------------|-----------|
| `MODE_GAMEPLAY` | All gameplay actions | All `ui_*` actions |
| `MODE_UI` | All `ui_*` + pause | All combat/movement actions |
| `MODE_CUTSCENE` | `ui_confirm`, `pause` only | Everything else |
| `MODE_DEAD` | `pause` only | Everything else |

Stack operations: `push_mode(mode)`, `pop_mode()`, `peek_mode()`. Maximum stack depth: 3. A fourth push replaces the current top.

**Stack examples:**
- Open pause mid-combat: `[GAMEPLAY]` → push UI → `[GAMEPLAY, UI]` → close → pop → `[GAMEPLAY]`
- Level-up AP screen: `[GAMEPLAY]` → push UI → `[GAMEPLAY, UI]` → confirm → pop → `[GAMEPLAY]`
- Sub-dialog from AP screen: `[GAMEPLAY, UI]` → push UI → `[GAMEPLAY, UI, UI]` → close → pop → `[GAMEPLAY, UI]`
- Cutscene: `[GAMEPLAY]` → push CUTSCENE → `[GAMEPLAY, CUTSCENE]` → ends → pop → `[GAMEPLAY]`

---

**7. Deadzone Configuration**

| Input | Deadzone | Purpose |
|-------|----------|---------|
| Analog stick (movement) | 0.20 (20%) | Prevents drift from causing unintended movement |
| Analog stick (action threshold) | 0.50 (50%) | Threshold for triggering digital actions from analog |
| Trigger axes (if used) | 0.10 (10%) | Trigger drift prevention |

Deadzone values are set per-action in Godot's InputMap. The 8-directional snap algorithm applies the movement deadzone (0.20) before snapping.

---

### States and Transitions

| Event | Mode Change | Effect |
|-------|-------------|--------|
| Game starts / loads | Stack = `[GAMEPLAY]` | All gameplay actions active |
| Player opens pause menu | Push `MODE_UI` | Combat inputs suppressed; UI navigation active |
| Player closes pause menu | Pop to `GAMEPLAY` | Combat inputs restored |
| HP reaches 0 | Push `MODE_DEAD` | All inputs suppressed except pause |
| Respawn | Pop to `GAMEPLAY` | Full input restored |
| Cutscene begins | Push `MODE_CUTSCENE` | Only advance/pause active |
| Cutscene ends | Pop | Return to whatever was beneath |
| Sub-dialog opens | Push `MODE_UI` | Nested UI context |
| Sub-dialog closes | Pop | Return to prior UI context |

---

### Interactions with Other Systems

| System | Reads from Input & Controls | Notes |
|--------|----------------------------|-------|
| **InputResolver** | `was_action_buffered()` for all bufferable actions; exposes `granted_actions` | Runs in `_physics_process()`; sole caller of `consume_buffer()` |
| **Movement** | `Input.get_vector("move_left","move_right","move_up","move_down")` (8-dir snapped), `jump` | Polled each physics frame |
| **Stamina** | `InputResolver` calls `stamina_system.can_execute(action)` | Stamina responds to the InputResolver query; does not query the buffer directly |
| **Combat** | `InputResolver.granted_actions` | Reads only from the granted list; never calls `was_action_buffered()` or `consume_buffer()` directly |
| **Menus & Navigation** | All `ui_*` actions | Active only when `MODE_UI` is on the stack |
| **Tutorial & Onboarding** | First-press detection on all gameplay actions | May call `was_action_buffered()` passively; must never call `consume_buffer()` |
| **Accessibility** | Full action remapping surface | Accessibility GDD defines the rebinding UI; this system provides the `InputMap` it writes to |

## Formulas

### Formula 1 — 8-Directional Movement Snap

`snapped_move = snap_to_8dir(raw_vector, deadzone)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Raw analog vector | `raw_vector` | Vector2 | (−1, −1) to (1, 1) | Direct readout from left stick or D-pad |
| Movement deadzone | `deadzone` | float | 0.0–1.0 | Minimum magnitude to register movement. `INPUT_DEADZONE_MOVE = 0.20` |
| Output direction | `snapped_move` | Vector2 | One of 9 values | Vector2.ZERO or one of 8 unit vectors at magnitude 1.0 |

**Algorithm:**
1. If `raw_vector.length() < deadzone`: return `Vector2.ZERO`
2. Compute `angle = atan2(raw_vector.y, raw_vector.x)`
3. Round to nearest 45°: `snapped_angle = round(angle / (PI/4)) * (PI/4)`
4. Return `Vector2(cos(snapped_angle), sin(snapped_angle))`

**Output Range:** Exactly one of: `Vector2.ZERO`, `(1,0)`, `(0.707, 0.707)`, `(0,1)`, `(−0.707, 0.707)`, `(−1,0)`, `(−0.707,−0.707)`, `(0,−1)`, `(0.707,−0.707)`

**Examples:**
- Raw `(0.8, 0.3)` → angle 20.6° → snapped 0° → `(1, 0)` (right)
- Raw `(0.6, 0.6)` → angle 45° → snapped 45° → `(0.707, 0.707)` (right-down)
- Raw `(0.1, 0.05)` → length 0.112 < deadzone → `Vector2.ZERO`

---

### Formula 2 — Input Buffer Query

`buffered = was_action_buffered(action, current_frame)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Action name | `action` | String | `"attack"`, `"dodge"`, `"parry"` | Bufferable actions only |
| Current physics frame | `current_frame` | int | 0–∞ | Incremented every physics tick |
| Recorded press frame | `press_frame[action]` | int | −1 or 0–∞ | Frame at which `is_action_just_pressed(action)` last returned `true`. −1 = no valid buffer. |
| Buffer window | `INPUT_BUFFER_FRAMES` | int | 1–5 (tunable) | Frames a press remains valid. Default: **3** (50 ms at 60 fps) |
| Output | `buffered` | bool | true / false | Whether a valid unconsumed press exists |

**Initialization:** `press_frame` must be initialized with `-1` for every bufferable action on `_ready()` — never `0`. Zero-initialization causes a false-positive on physics frame 0: `(0 - 0) = 0 ≤ 3` returns `true` with no input. Correct: `press_frame = {"attack": -1, "dodge": -1, "parry": -1}`.

**Algorithm:**
```
was_action_buffered(action, current_frame):
  if press_frame[action] == -1: return false
  if (current_frame - press_frame[action]) <= INPUT_BUFFER_FRAMES: return true
  press_frame[action] = -1   # expire
  return false
```

Note: `was_action_buffered()` has a state-mutation side effect on the expiry branch (`press_frame[action] = -1`). It is not a pure read. Call order matters on the frame of expiry: whichever system calls it first triggers the expiry write.

**Consumption:** The `InputResolver` node (§2a) is the **sole caller** of `consume_buffer(action)` → sets `press_frame[action] = -1`. No other system may call `consume_buffer()` directly. This enforces the single-consumer contract and prevents a single press from triggering multiple systems within the buffer window.

**Example:** Parry pressed frame 100. Buffer window = 3.
- Frame 101: 1 ≤ 3 → `true`; Frame 103: 3 ≤ 3 → `true`; Frame 104: 4 > 3 → `false`, expired.
- If consumed on frame 101: all subsequent queries on frame 101–103 return `false`.

---

### Formula 3 — Action Priority Resolution

`winning_action = resolve_priority(buffered_actions)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Buffered action set | `buffered_actions` | Set\<String\> | Subset of {attack, dodge, parry} | All bufferable actions returning `was_action_buffered() == true`. Non-bufferable actions (`jump`, `interact`) never appear here — they are handled by direct `is_action_just_pressed()` polling outside this formula. |
| Priority order | — | const | parry > dodge > attack | Fixed at design time. `jump` and `interact` are not buffered so they cannot conflict with buffered actions; they are resolved by their own polling path. |
| Output | `winning_action` | String or null | One action name, or null | Highest-priority buffered action |

**Algorithm:** Iterate priority list in order; return the first action in `buffered_actions`.

**Examples:**
- `{"attack", "dodge"}` → `"dodge"`
- `{"parry", "attack"}` → `"parry"`
- `{}` → `null`

## Edge Cases

- **If a bufferable action is pressed twice before the first is consumed**: The newer press overwrites the buffer. `press_frame[action]` is updated to the most recent frame; the earlier press is discarded.

- **If `dodge` and `parry` are pressed on the same frame**: `parry` wins via priority. The dodge buffer is preserved (not consumed). The dodge buffer retains its standard `INPUT_BUFFER_FRAMES`-frame window from the original press time — it is not extended. The parry animation lasts approximately 21 frames (0.35 s at 60 fps, from Character Stats GDD). Because the buffer window (3 frames) is shorter than the parry animation, the dodge buffer will expire before the parry completes. The player must re-press dodge after the parry animation ends to execute a dodge escape.

- **If input arrives while mode stack top is `MODE_DEAD` or `MODE_CUTSCENE`**: Gameplay actions are suppressed. Their buffer queries return `false` regardless of physical button state.

- **If `push_mode()` is called at stack depth 3**: Replaces the current top instead of adding a fourth entry. Stack max depth is 3. A warn-level log entry is emitted.

- **If `pop_mode()` is called on a stack of `[MODE_GAMEPLAY]` only**: No-op. Gameplay is the base context and cannot be popped. A warn-level log entry is emitted.

- **If gamepad is disconnected mid-game**: Input falls back to keyboard/mouse bindings for the same named actions. No gameplay state changes. Reconnection resumes gamepad priority silently.

- **If a player attempts to bind an action to a key/button already bound to another action**: The rebind is blocked. An inline error prompt names the conflicting action. The player must first clear the conflicting action's binding before the new binding is accepted. Duplicate bindings are not permitted.

- **If analog stick magnitude is exactly 0.20 (deadzone boundary)**: Treated as active — condition is `< 0.20` (exclusive). Magnitude ≥ 0.20 triggers 8-directional snap.

- **If W and D keys are held simultaneously**: Raw vector `(1, −1)` → normalized `(0.707, −0.707)` → snapped to right-up diagonal. Valid 8-directional input.

- **If a buffered `parry` press expires during an animation lock**: Silent discard after `INPUT_BUFFER_FRAMES` frames. Executing a parry 4+ frames late is incorrect in frame-accurate Soulslike design.

- **If `ui_confirm` and `ui_cancel` are pressed simultaneously in `MODE_UI`**: Cancel takes priority. Accidental confirmation is more harmful than accidental cancellation.

- **If a buffered combat press exists when `push_mode()` is called**: All buffered combat inputs (`attack`, `dodge`, `parry`) are cleared on any mode push. Buffered gameplay inputs must not leak into non-gameplay contexts.

## Dependencies

**Upstream (this system depends on):** None — Input & Controls is a Foundation-layer system with no upstream dependencies.

**Downstream (these systems depend on Input & Controls):**

| System | What they need | Interface |
|--------|----------------|-----------|
| **InputResolver** (internal) | `was_action_buffered()`, `consume_buffer()` | Runs once per physics frame; mediates Stamina ↔ Combat; sole consumer of the buffer |
| **Movement** | `Input.get_vector("move_left","move_right","move_up","move_down")` (8-dir snapped Vector2), `jump` bool | Polled each physics frame |
| **Stamina** | Receives `can_execute(action)` query from InputResolver | Stamina does not read the buffer; it responds to the InputResolver query with a bool grant/deny |
| **Combat** | `InputResolver.granted_actions: Array[String]` | Reads granted actions; never queries the buffer or consumes directly |
| **Menus & Navigation** | All `ui_*` actions | Active only when `MODE_UI` is on the stack; handled via Godot Control `_gui_input()` events |
| **Tutorial & Onboarding** | First-press detection for all gameplay actions | Reads `was_action_buffered()` passively; must never call `consume_buffer()` |
| **Accessibility** | Full remapping API | Writes new bindings to `InputMap`; this system exposes the current map as authoritative |

**Cross-document coordination required:**
- **Movement GDD** must confirm compatibility with the 8-directional unit vector format and specify which physics frame step consumes the movement vector
- **Stamina GDD** must implement `stamina_system.can_execute(action) → bool` — the query interface the `InputResolver` node calls each physics frame before granting any buffered action. Stamina owns the permission logic; InputResolver owns the execution sequencing
- **Combat GDD** must confirm it reads exclusively from `InputResolver.granted_actions` — never from `was_action_buffered()` directly — and never calls `consume_buffer()` directly
- **Skills & Abilities GDD** must define bindings for `skill_1`, `skill_2` and specify buffer behavior (bufferable or not) and priority table position for skill actions
- **Companion AI GDD** must define binding for `companion_command` and specify behavior in each input mode
- **Accessibility GDD** must define the rebinding UI contract: binding storage format (local settings file vs. user profile), and whether bindings persist to cloud save

## Tuning Knobs

| Knob | Location | Current Value | Safe Range | Too High → | Too Low → |
|------|----------|---------------|-----------|------------|-----------|
| `INPUT_BUFFER_FRAMES` | Formula 2 | 3 frames (50 ms) | 1–6 | Parry/dodge inputs fire long after the player intended; wrong actions execute mid-combo | Tight presses are dropped; player feels the game doesn't respond. Especially damaging for parry on Gamepad |
| `INPUT_DEADZONE_MOVE` | Formula 1 | 0.20 (20%) | 0.10–0.35 | Stick drift triggers movement when player is idle | Stutter at very low stick deflections; diagonal snapping activates too easily |
| `INPUT_DEADZONE_ACTION` | Core Rules §7 | 0.50 (50%) | 0.30–0.70 | Analog stick can't trigger digital actions without pushing hard | Actions trigger from accidental nudges; player attacks unintentionally |
| `INPUT_DEADZONE_TRIGGER` | Core Rules §7 | 0.10 (10%) | 0.05–0.25 | Trigger actions require deliberate press | Trigger actions fire from resting finger pressure |
| `INPUT_STACK_MAX_DEPTH` | Core Rules §6 | 3 | 2–4 | Higher allows deeper nesting if needed | 2 would break GAMEPLAY → UI → sub-dialog flow |

**Interaction warning**: `INPUT_BUFFER_FRAMES` and the parry window (350 ms = ~21 frames, locked from prototype via Character Stats GDD) must be tuned together. The buffer window should not exceed 25% of the parry window (~5 frames) to prevent unintentional parry execution blurring the parry skill ceiling.

## Visual/Audio Requirements

Input & Controls has no direct visual output. All combat feedback (parry flash, dodge I-frame visual, hit stun VFX) belongs to Combat and Movement GDDs.

**Haptic feedback** (gamepad rumble — owned here as the system closest to the input device):

| Event | Motor | Duration | Intensity | Notes |
|-------|-------|----------|-----------|-------|
| Parry success | Both motors | 80 ms | Low-left, High-right | Sharp "click" feel reinforcing timing mastery |
| Player takes hit (hit stun) | Both motors | 200 ms | Medium (0.4) | Conveys weight of taking damage |
| Stagger break (enemy) | Right motor only | 150 ms | High (0.8) | Celebratory; distinct from damage rumble |
| Player death | Both motors, fade out | 600 ms | High → 0 | Controller going quiet = character going down |

Haptic is disabled when no gamepad is connected. All intensity values are tuning knobs. Haptic intensity must be configurable via accessibility settings (Accessibility GDD owns the toggle/slider).

## UI Requirements

Two screens depend on this system:

1. **Key Rebinding Screen** — displayed in Options/Settings menu. Shows all rebindable gameplay actions with current gamepad and keyboard/mouse bindings side-by-side.

   **Rebindable actions shown:** `move_left`, `move_right`, `move_up`, `move_down`, `attack`, `dodge`, `parry`, `jump`, `interact`, `skill_1`, `skill_2`, `companion_command`.

   **Non-rebindable (not shown):** `pause` (read-only, shown as a footer note). All `ui_*` actions are not shown — UI navigation bindings are system-managed and not player-configurable.

   **Capture state machine:** idle → selected (player highlights an action row) → listening (player activates a binding slot; UI shows "Press any key…") → captured (new input received; binding updates) → saved (written to InputMap on screen close or manual confirm).

   **Conflict resolution:** If the captured input is already bound to another action, block the rebind and show an inline error prompt naming the conflicting action (e.g., "J is already bound to Attack — unbind Attack first"). The new binding is not applied. Player must manually unbind the conflicting action first. Duplicate bindings are not permitted.

   **Unbinding:** A "Clear" control on each row sets that slot to Unbound. Player can unbind an action slot intentionally.

   **Reset to defaults:** A "Reset All to Default" button restores all gameplay actions to their factory defaults.

   **Required action warning:** Warn before closing (modal confirmation) if any of the following are Unbound: `attack`, `dodge`, `parry`, `jump`. Player may dismiss the warning and proceed. `interact`, `skill_1`, `skill_2`, `companion_command` may be Unbound without warning.

   **Unbound display:** Slots with no binding display "— Unbound —" in the binding cell.

2. **Input Method Icon Switching** — all in-game UI referencing a button (tutorial prompts, interaction indicators, AP allocation hints) must detect the active input device and display the appropriate glyph (PS face buttons / Xbox face buttons / keyboard key label). Switch is automatic and instant when the player changes input device. No confirmation prompt.

> **📌 UX Flag — Input & Controls**: Run `/ux-design` in Phase 4 (Pre-Production) to create UX specs for the Key Rebinding Screen and Input Icon system before writing implementation epics. Stories referencing these UIs should cite `design/ux/key-rebinding.md` and `design/ux/input-icons.md`, not this GDD directly.

## Acceptance Criteria

*Story Type: Logic — all criteria require passing automated unit tests in `tests/unit/input/` before any implementing story is marked Done.*

### Action Map

**AM-01** — GIVEN the game starts, WHEN the InputMap is queried, THEN the actions `move_left`, `move_right`, `move_up`, `move_down`, `attack`, `dodge`, `parry`, `jump`, `interact`, `pause`, `ui_up`, `ui_down`, `ui_left`, `ui_right`, `ui_confirm`, `ui_cancel`, `ui_tab_next`, `ui_tab_prev` all exist with at least one gamepad binding and one keyboard/mouse binding each. Actions `skill_1`, `skill_2`, `companion_command` exist in the InputMap as registered entries but may have no bindings (TBD by their respective GDDs).

**AM-02** — GIVEN default bindings are loaded, WHEN `attack` is queried for its gamepad binding, THEN the binding matches Square (PS) / X (Xbox). When queried for keyboard, it matches J.

**AM-03** — GIVEN default bindings, WHEN `parry` is queried for its gamepad binding, THEN it maps to L1 (PS) / LB (Xbox) — a different button than `dodge` (Circle/B). The two actions share no physical button in their default layout.

### 8-Directional Snap (Formula 1)

**FD-01** — GIVEN a raw analog vector of `(0.8, 0.3)` (magnitude 0.854), WHEN `snap_to_8dir()` is called with deadzone 0.20, THEN the output is `(1, 0)` (right).

**FD-02** — GIVEN a raw vector of `(0.6, 0.6)` (magnitude 0.849), WHEN `snap_to_8dir()` is called, THEN the output is `(0.707, 0.707)` (right-down diagonal).

**FD-03** — GIVEN a raw vector of `(0.1, 0.05)` (magnitude 0.112), WHEN `snap_to_8dir()` is called with deadzone 0.20, THEN the output is `Vector2.ZERO`.

**FD-04** — GIVEN a raw vector with magnitude exactly 0.20, WHEN `snap_to_8dir()` is called with deadzone 0.20, THEN the output is a non-zero snapped direction (magnitude 0.20 is ≥ deadzone).

**FD-05** — GIVEN keyboard keys W and D held simultaneously, WHEN `snap_to_8dir()` processes the resulting raw vector `(1, -1)`, THEN the output is `(0.707, -0.707)` (right-up diagonal).

### Input Buffer (Formula 2)

**FD-06** — GIVEN `parry` is pressed on frame 100 and `INPUT_BUFFER_FRAMES = 3`, WHEN `was_action_buffered("parry", 103)` is called, THEN result is `true` (100 + 3 = 103 ≤ 103).

**FD-07** — GIVEN `parry` was pressed on frame 100 and `INPUT_BUFFER_FRAMES = 3`, WHEN `was_action_buffered("parry", 104)` is called, THEN result is `false` (buffer expired).

**FD-08** — GIVEN `attack` was pressed on frame 50 and `consume_buffer("attack")` was called on frame 51, WHEN `was_action_buffered("attack", 51)` is called after consumption, THEN result is `false`.

**FD-09** — GIVEN `dodge` was pressed on frame 200, WHEN `dodge` is pressed again on frame 202, THEN `press_frame["dodge"]` is 202 (newer press overwrites older).

### Priority Resolution (Formula 3)

**FD-10** — GIVEN `buffered_actions = {"attack", "dodge"}`, WHEN `resolve_priority()` is called, THEN result is `"dodge"`.

**FD-11** — GIVEN `buffered_actions = {"parry", "attack", "dodge"}`, WHEN `resolve_priority()` is called, THEN result is `"parry"`.

**FD-12** — GIVEN `buffered_actions = {}`, WHEN `resolve_priority()` is called, THEN result is `null`.

**FD-13** — GIVEN `buffered_actions = {"attack"}` (only attack buffered, no dodge or parry), WHEN `resolve_priority()` is called, THEN result is `"attack"`. (Note: `interact` and `jump` are non-bufferable and can never appear in `buffered_actions`; priority resolution is only defined over the three bufferable actions.)

### Input Mode Stack

**ST-01** — GIVEN the game starts, WHEN `peek_mode()` is called, THEN result is `MODE_GAMEPLAY`.

**ST-02** — GIVEN current stack is `[GAMEPLAY]` and `press_frame["attack"] = current_frame` (attack buffered), WHEN `push_mode(MODE_UI)` is called, THEN `peek_mode()` returns `MODE_UI` AND `was_action_buffered("attack", current_frame + 1)` returns `false` AND `was_action_buffered("dodge", current_frame + 1)` returns `false` AND `was_action_buffered("parry", current_frame + 1)` returns `false` (all buffered combat inputs cleared on any mode push).

**ST-03** — GIVEN current stack is `[GAMEPLAY, UI]` and no buffered actions, WHEN `pop_mode()` is called, THEN `peek_mode()` returns `MODE_GAMEPLAY` AND `InputResolver.granted_actions` is empty (no spurious grants on the pop frame itself).

**ST-04** — GIVEN current stack is `[GAMEPLAY, UI, UI]` (depth 3), WHEN `push_mode(MODE_GAMEPLAY)` is called, THEN `peek_mode()` returns `MODE_GAMEPLAY` (top was replaced), stack depth is still 3 (no fourth entry added), and a warn-level log entry is emitted with a non-empty message string.

**ST-05** — GIVEN current stack is `[GAMEPLAY]`, WHEN `pop_mode()` is called, THEN stack remains `[GAMEPLAY]` and a warn-level log entry is emitted.

**ST-06** — GIVEN `press_frame["parry"] = 50` (buffered), WHEN `push_mode(MODE_CUTSCENE)` is called, THEN `was_action_buffered("parry", 51)` returns `false` (buffer cleared on push).

### Edge Cases

**EC-01** — GIVEN `dodge` pressed on frame 10 (buffer = 3), WHEN `dodge` pressed again on frame 12, THEN `press_frame["dodge"]` is 12.

**EC-02** — GIVEN `dodge` and `parry` pressed on the same frame, WHEN `resolve_priority()` is called and `consume_buffer("parry")` executes, THEN `was_action_buffered("dodge")` still returns `true`.

**EC-03** — GIVEN mode stack top is `MODE_DEAD`, WHEN `attack` button is pressed, THEN `was_action_buffered("attack")` returns `false`.

**EC-04** — GIVEN `ui_confirm` and `ui_cancel` arrive on the same frame in `MODE_UI`, WHEN both events are processed, THEN `ui_cancel` is the active event and `ui_confirm` is discarded.

### L1 Dual-Mapping

**DM-01** — GIVEN the mode stack peek is `MODE_GAMEPLAY` and the player presses L1, WHEN `InputResolver` runs, THEN `was_action_buffered("parry", current_frame)` returns `true` and `ui_tab_prev` is not triggered.

**DM-02** — GIVEN the mode stack peek is `MODE_UI` and the player presses L1, WHEN input is processed, THEN `ui_tab_prev` fires (via the `_gui_input()` pipeline) and `was_action_buffered("parry", current_frame)` returns `false` (gameplay actions suppressed in MODE_UI).

### Move Magnitude Invariant

**FD-14** — GIVEN any raw analog input with `raw_vector.length() >= 0.20`, WHEN `snap_to_8dir()` is called, THEN the output magnitude is exactly 1.0 (within floating-point epsilon, i.e., `abs(output.length() - 1.0) < 0.0001`).

**FD-15** — GIVEN any raw analog input with `raw_vector.length() < 0.20`, WHEN `snap_to_8dir()` is called, THEN the output is exactly `Vector2.ZERO`.

### Initialization Guard

**FD-16** — GIVEN the buffer is initialized with `press_frame = {"attack": -1, "dodge": -1, "parry": -1}`, WHEN `was_action_buffered("attack", 0)` is called on physics frame 0 with no input having occurred, THEN result is `false` (no false positive from zero-initialization).

## Open Questions

1. **Haptic feedback accessibility** — Should haptic intensity be a slider (0–100%) or a simple on/off toggle? Owner: Accessibility GDD. Resolve when authoring that GDD.

2. **Rebinding persistence model** — Are custom bindings saved to a user profile (cloud-saveable) or a local machine settings file? Owner: Save & Load GDD. Resolve when authoring that GDD.

3. **Input debug overlay** — Should there be a developer-only input echo HUD (shows buffer states per action each physics frame) for QA and tuning? Advisory — does not need resolution before MVP implementation.

4. ~~**"Reset to defaults" in rebinding screen**~~ — **RESOLVED**: "Reset All to Default" button added to the rebinding screen spec in UI Requirements §1. Per-action "Clear" also specified. UX details deferred to `design/ux/key-rebinding.md`.
