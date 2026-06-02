# Health & Death

> **Status**: Revised (post design-review 2026-06-02)
> **Author**: Design session + agents
> **Last Updated**: 2026-06-02
> **Implements Pillar**: Pillar 2 (Fear Becomes Confidence)
> **Layer**: Gameplay | **Priority**: MVP | **Design Order**: #6

## Overview

Health & Death is the entity lifecycle system — the authoritative tracker of current HP for every entity that can be damaged: the player character, all enemies, and AI companions. At the infrastructure level, it owns a single responsibility: maintain `current_health`, receive `apply_damage(amount)` calls from Combat (which has already computed the final damage value after defense and type-reduction), and emit `health_changed` and `died` signals when the state changes. It does not calculate damage — that belongs to Combat — and it does not respawn — that belongs to Checkpoint & Respawn. It simply keeps score and fires events.

At the player level, Health & Death is where Pillar 2 becomes tangible. The HP bar is the fear-to-confidence arc made visible: a Lv1 Warrior with 105 HP looks daunting to a new player and trivially safe to the same player at level 30. Every hit that lands is a reminder that standing still costs something. Running at critical health — 10–15% remaining, bar flashing — is its own emotional state: survival instinct, heightened focus, every decision sharpened by proximity to death. That feeling is not incidental. It is the point. Health & Death's job is to make HP feel like it matters.

This system also resolves the game's healing model. Whether the player recovers HP through a limited-use restore, consumable items, companion intervention, or some combination is answered here and nowhere else. That decision shapes the entire risk/reward loop of every encounter.

## Player Fantasy

Health & Death's player fantasy is not about health — it's about the cost of failure. Every hit that connects is a message: you read that wrong. The HP bar isn't a resource you manage; it's a running record of every mistake the world has made you pay for. When it's full, you feel capable. When it's dropping, you feel accountable.

**The weight of every hit.** Ashen Maple's Soulslike design promise is that nothing hits you arbitrarily — every hit landed was a pattern you missed, a dodge you timed wrong, a parry you misjudged. This makes damage feel earned rather than random. A player who takes a hit should think "I know what I did" — and a player who takes zero hits in a fight should feel genuinely proud. HP is the score.

**Critical health as a heightened state.** When HP falls below the critical threshold (~20%), the experience shifts. Not panic — sharpened focus. This is Pillar 2's fear-to-confidence arc in real time: the same player who froze at low HP in hour one is reading the enemy patterns perfectly at hour ten, surviving on a sliver of health because they know exactly when the opening comes. That transition — from "I'm going to die" to "I see it" — is what Health & Death exists to enable.

**Healing as a decision, not a reset.** The healing system is not a reset button. Every heal is a resource committed, a window used, a choice made. Players who understand when to heal versus when to press advantage are better players. The fantasy is the moment you judge it right — hold through the pressure, heal at the gap, survive. Not the heal itself; the read that made the heal possible.

**Death as the teacher, not the punishment.** The game concept is explicit: "Death always teaches something — it is never arbitrary." Health & Death's death state fulfills that promise. When the HP bar empties, the question is always "what do I do differently next time?" — never "why did that happen?"

## Detailed Design

### Core Rules

**1. HP Tracking**

Every damageable entity (player, enemies, companions) has:
- `current_health: int` — initialized to `max_health` on spawn; clamped to `[0, max_health]` at all times
- `max_health: int` — read from Character Stats; Health & Death subscribes to `stat_changed("max_health")` to track changes

`current_health` never goes negative. A value of 0 means the entity is dead.

---

**2. Receiving Damage**

`apply_damage(amount: int)` is called by Combat with a pre-calculated value (Combat owns defense and type-reduction math). Health & Death applies it:

- If `amount ≤ 0` or entity is DEAD: no-op
- `old_health = current_health`
- `current_health = max(0, current_health − amount)`
- Emit `health_changed(old_health, current_health)`
- If `current_health == 0`: trigger death (Rule 5)
- If crossing critical threshold (Rule 6): emit appropriate signal

---

**2b. Applying Heals**

`apply_heal(amount: int)` is called internally by the Estus flow (step 6) and by Companion AI. Health & Death applies it:

- If entity is DEAD: no-op — dead entities cannot be healed; return immediately
- If `amount ≤ 0`: no-op — negative or zero heal is discarded; no signals emitted
- If `current_health == max_health`: no-op — HP is already full; no `health_changed` signal emitted
- `old_health = current_health`
- `current_health = min(max_health, current_health + amount)`
- Emit `health_changed(old_health, current_health)`
- If crossing critical threshold upward (Rule 6): emit `critical_health_exited`

`apply_heal()` does NOT check HEALING state — the HEALING sub-state guard (preventing a second Estus during an active heal) is enforced by the heal action input flow (Rule 3, step 2). Companion AI enforces the HEALING guard before calling `apply_heal()` (Rule 4).

---

**3. Estus Healing**

The player has a limited-use heal charge. `current_heal_charges: int` is initialized to `HEAL_CHARGES_BASE = 3` and refilled to `HEAL_CHARGES_BASE` whenever the player touches a checkpoint (Checkpoint & Respawn calls `refill_charges()`).

**Heal action flow:**
1. Player presses the heal action (input binding TBD — reserved in Input & Controls)
2. If entity is DEAD or HEALING: action denied (no-op)
3. If `current_heal_charges == 0`: emit `heal_empty_triggered` signal (for testability), play empty-flask animation (~0.30s, interruptible, no movement lock, no charge cost, no HP restored) — then stop. Do not proceed to step 4.
4. Charge immediately decremented by 1 (`current_heal_charges -= 1`). The charge is committed on press — spending it is the risk.
5. Movement enters a HEALING sub-state: `velocity.x = 0` for the heal animation duration (cross-doc coordination required with Movement GDD — see Dependencies)
6. At `HEAL_COMMIT_TIME = 0.50s`:
   - `apply_heal(HEAL_AMOUNT)` fires: `current_health = min(max_health, current_health + HEAL_AMOUNT)`
   - Emit `health_changed(old, new)`
7. At `HEAL_DURATION = 1.0s`: HEALING state ends, movement resumes

**Interrupt rule:** If the player takes damage before `HEAL_COMMIT_TIME` (0.50s): Movement transitions to HIT_STUN, HEALING is cancelled, HP is NOT restored. The charge already spent is gone. After `HEAL_COMMIT_TIME`, any incoming damage resolves normally — HP was already restored.

**Same-frame ordering:** Within a single physics frame, the heal commit check (`elapsed ≥ HEAL_COMMIT_TIME`) is evaluated BEFORE `apply_damage()` is processed. A hit that arrives on the exact same frame as the commit point is treated as arriving after commit — HP is restored first, then the damage applies to the post-heal value. This is a deliberate playability choice.

`HEAL_AMOUNT = round(max_health × HEAL_PERCENT)` where `HEAL_PERCENT = 0.40` (tunable). Computed from the entity's `max_health` at the moment of commit, not at press time.

---

**4. Companion Healing**

When a Healer companion is present, it independently monitors the player's HP ratio each physics frame. The companion initiates a heal when ALL of the following are true:
- `float(current_health) / float(max_health) ≤ COMPANION_HEAL_THRESHOLD (0.18)`
- `companion_heal_cooldown_remaining ≤ 0`
- `companion_heal_triggers_this_encounter < COMPANION_MAX_TRIGGERS`
- Player is NOT in HEALING state (mid-Estus animation)

1. Companion initiates a heal animation (Companion AI owns this logic)
2. Immediately on animation start: calls `player.apply_heal(round(player.max_health × COMPANION_HEAL_PERCENT))` where `COMPANION_HEAL_PERCENT = 0.30`
3. Resets `companion_heal_cooldown_remaining = COMPANION_HEAL_COOLDOWN (20.0s)`
4. Increments `companion_heal_triggers_this_encounter` by 1

**Companion heals are instantaneous and uninterruptible.** The heal fires at animation start (step 2), not at an animation commit point. Once the companion initiates, the heal always completes — there is no interrupt window or commit risk. The companion bears all timing risk so the player doesn't have to.

**If the player is in HEALING state when the threshold is met:** The companion does NOT initiate the animation and the trigger count does NOT increment. The companion will retry next time the threshold is met and the cooldown has expired. This ensures no rescue trigger is silently consumed by a no-op.

This is entirely AI-driven — the player cannot command it. This is intentional: Pillar 3 requires unscripted mutual rescue moments, not on-demand healing buttons. If multiple Healer companions are present, each has an independent cooldown and trigger counter.

---

**5. Death**

When `current_health` reaches 0:
- Emit `died(entity: Node)` signal
- Entity enters DEAD state
- While DEAD: `apply_damage()` and `apply_heal()` are no-ops
- Only Checkpoint & Respawn can exit DEAD state via `respawn(position: Vector2)`

On respawn: `current_health = max_health`, DEAD state exits, Movement resets to IDLE at respawn position.

---

**6. Critical Health Threshold**

When `float(current_health) / float(max_health)` falls to or below `CRITICAL_THRESHOLD (0.20)`:
- Emit `critical_health_entered` signal (once, on the transition frame)

When `float(current_health) / float(max_health)` rises above `CRITICAL_THRESHOLD` (from a heal):
- Emit `critical_health_exited` signal (once, on the transition frame)

> **Implementation note:** Always use `float(current_health) / float(max_health)`. In GDScript, `int / int` performs integer division — `21 / 105 = 0`, not `0.20` — which would cause `critical_health_entered` to fire at virtually every HP value.

HUD subscribes to both signals to display visual feedback (pulsing HP bar, color shift). Audio subscribes for the low-health audio cue. No mechanical gameplay change — the signals are informational only.

---

**7. max_health Changes**

When `stat_changed("max_health", old_val, new_val)` is received:
- If `new_val < current_health` and entity is in ALIVE or HEALING state: `current_health = max(1, new_val)` — HP cannot reach 0 from a stat change. Only `apply_damage()` can kill. (Debuff/equipment GDDs must ensure `max_health` never reaches 0; an `max_health = 0` result is an unsupported state.)
- If `new_val < current_health` and entity is DEAD: `current_health` remains 0 (dead entities are not affected by the 1 HP floor).
- If `new_val ≥ current_health`: `current_health` unchanged (HP is not healed by a max_health increase)
- In all cases: emit `health_changed(old_current, new_current)` if `current_health` changed

---

### States and Transitions

| State | Condition | apply_damage | apply_heal | Movement |
|-------|-----------|-------------|------------|----------|
| ALIVE | current_health > 0 | Normal | Normal | Unrestricted |
| HEALING | ALIVE + heal animation active. **In-state event at elapsed ≥ HEAL_COMMIT_TIME:** `apply_heal(HEAL_AMOUNT)` fires internally — HP restored, `health_changed` emitted — state remains HEALING. State does not exit until elapsed ≥ HEAL_DURATION. | Cancels heal if elapsed < HEAL_COMMIT_TIME; charge already lost | No-op | velocity.x = 0 |
| DEAD | current_health == 0 | No-op | No-op | Velocity zeroed (Movement DEAD state) |

| Transition | From | To | Trigger |
|-----------|------|----|---------|
| Take fatal damage | ALIVE | DEAD | current_health reaches 0 |
| Start heal | ALIVE | HEALING | Heal pressed, charges > 0, not DEAD or HEALING |
| Heal complete | HEALING | ALIVE | elapsed ≥ HEAL_DURATION (animation ends, movement resumes) |
| Heal interrupted | HEALING | ALIVE (via HIT_STUN) | apply_damage called before HEAL_COMMIT_TIME |
| Respawn | DEAD | ALIVE | Checkpoint & Respawn calls respawn() |

---

### Interactions with Other Systems

| System | Interface |
|--------|-----------|
| **Character Stats** | Reads `max_health` on init; subscribes to `stat_changed("max_health")` for runtime updates |
| **Combat** | Calls `apply_damage(amount: int)` — amount is fully pre-calculated (post-defense, post-reduction) |
| **Checkpoint & Respawn** | Calls `respawn(position)` to exit DEAD state and restore full HP; calls `refill_charges()` on checkpoint touch |
| **Companion AI** | Reads `current_health` and `max_health`; calls `apply_heal(amount)` when heal criteria are met |
| **Input & Controls** (via InputResolver) | Guards heal action: denies if `current_heal_charges == 0` or DEAD or HEALING |
| **Movement** | Must add HEALING state to suppress `velocity.x` during heal animation (cross-doc coordination required — see Dependencies) |
| **HUD** | Subscribes to `health_changed`, `critical_health_entered`, `critical_health_exited`, `died` |
| **Audio** | Subscribes to `critical_health_entered` for low-health audio cue; `died` for death sound |
| **Tutorial & Onboarding** | Reads `current_health / max_health` for first-critical-health detection |

## Formulas

All formulas validated by `systems-designer`. Percentage-based healing ensures charges remain meaningful at every level tier.

---

### Formula 1 — Estus Heal Amount

`HEAL_AMOUNT = round(max_health × HEAL_PERCENT)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Entity max HP | `max_health` | int | 60–∞ (practical Lv1: 80–105) | From Character Stats; read at moment of heal commit (0.50s), not at press time. Floor of 60 applies for STR=0 entities at Lv1 (per Character Stats EC-10 — enemies may have STR=0). If `max_health` is derived from a composed STR float (e.g., STR×multiplier = 9.9), the float flows through the formula and the output is rounded — do not round STR before use. |
| Heal percentage | `HEAL_PERCENT` | float (constant) | 0.40 | Fraction of max_health restored per charge; owned by this GDD |
| Heal amount | `HEAL_AMOUNT` | int (rounded) | 32–660+ | HP restored; rounded to nearest integer |

**Output range:** Lv1 Mage → 32 HP | Lv1 Warrior → 42 HP | Lv30 Warrior → 320 HP | Lv60 Warrior → 660 HP

**Examples:**
- Lv1 Warrior (max_health=105): `round(105 × 0.40) = 42 HP` — recovers from ~2–3 hits ✓
- Lv30 Warrior (max_health=800): `round(800 × 0.40) = 320 HP` — remains ~2–3 hits at that level ✓

**Design note:** Percentage-based healing means the Estus charge remains equally meaningful at every level — always recovers approximately 2–3 hits regardless of progression stage.

---

### Formula 2 — Companion Heal Amount

`COMPANION_HEAL_AMOUNT = round(player.max_health × COMPANION_HEAL_PERCENT)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Player max HP | `max_health` | int | 60–∞ | Player's current max_health; read at moment companion heal fires. Floor of 60 applies for STR=0 entities (per Character Stats EC-10). |
| Companion heal percentage | `COMPANION_HEAL_PERCENT` | float (constant) | 0.30 | Fraction of player max_health restored per companion heal; owned by this GDD |
| Companion heal amount | `COMPANION_HEAL_AMOUNT` | int (rounded) | 24–495+ | HP restored to player |

**Output range:** Lv1 Mage → 24 HP | Lv1 Warrior → 32 HP | Lv30 Warrior → 240 HP | Lv60 Warrior → 495 HP

**Examples:**
- Lv1 Warrior (105 HP): `round(105 × 0.30) = 32 HP` — ~1.5–2 hits recovered ✓
- Lv60 Warrior (1650 HP): `round(1650 × 0.30) = 495 HP` — scales appropriately ✓

**Design note:** Companion heal is smaller than Estus (30% vs 40%) because it is free and instantaneous — it fires without player action and has no commit window or interrupt risk. The companion bears all timing risk; the asymmetry keeps Estus charges feeling more valuable. `COMPANION_HEAL_THRESHOLD = 0.18` is set inside the critical zone (`CRITICAL_THRESHOLD = 0.20`) so the companion rescues the player during peak fear — the player enters critical state, sees the HP bar pulse and hears the audio cue, and then the companion fires. This sequence is what makes the rescue a Pillar 3 moment rather than routine maintenance. Charge loss on an interrupted Estus heal is an intentional teaching cost — the commitment risk that motivates pattern learning and identifying safe heal windows before committing.

**Companion heal guard constants (tunable):**
- `COMPANION_HEAL_THRESHOLD = 0.18` — player must be at or below 18% HP to trigger (inside the critical zone)
- `COMPANION_HEAL_COOLDOWN = 20.0s` — seconds before the same companion can heal again
- `COMPANION_MAX_TRIGGERS = 2` — maximum companion heals per encounter; resets on new encounter; preserves the "rare rescue moment" of Pillar 3

## Edge Cases

- **If `apply_damage(amount)` is called while the entity is DEAD**: No-op. HP remains at 0. The `died` signal has already fired; Combat must not call `apply_damage` on a dead entity, but Health & Death defends against it.

- **If `apply_damage(amount)` is called with `amount ≤ 0`**: No-op. Negative or zero damage is not applied. No signals are emitted.

- **If `apply_damage` would reduce `current_health` below 0**: `current_health` is clamped to 0. Excess damage is discarded — there is no overkill value or penalty beyond death.

- **If `apply_heal(amount)` is called while the entity is DEAD**: No-op. Dead entities cannot be healed. Only Checkpoint & Respawn can restore an entity from DEAD state.

- **If `apply_heal(amount)` is called when `current_health == max_health`**: No-op. HP cannot exceed `max_health`. No `health_changed` signal is emitted.

- **If the player attempts to use an Estus charge while `current_heal_charges == 0`**: Health & Death plays a short **empty-flask animation** (~0.30s, exact duration owned by Animation GDD). No HP is restored, no charge is spent, movement is not locked. The animation serves dual purpose: clear feedback that the resource is exhausted, and a soft punishment — the brief window represents wasted action time that a resource-aware player would not spend. The empty-flask animation is immediately interruptible by taking damage, with no commit time or charge cost.

- **If damage is taken before `HEAL_COMMIT_TIME` (0.50s) during a heal animation**: HEALING is cancelled. HP is NOT restored. The charge spent at press time (step 4) is gone — this is the commitment cost. The incoming damage triggers HIT_STUN via the Movement system normally.

- **If damage is taken at `HEAL_COMMIT_TIME` or after**: HP has already been restored at commit time. The damage resolves against the post-heal `current_health`. Taking damage after commit does not undo the heal.

- **If two companion heals would fire on the same frame** (two Healer companions both meeting the threshold simultaneously): Each companion checks ALL guard conditions independently (threshold, cooldown, trigger count, NOT in HEALING state). The trigger count increment (step 4) must be treated as atomic within the physics frame — the first companion to run claims the slot, incrementing the counter before the second companion checks. In GDScript's single-threaded physics loop, scene tree order determines execution priority; Companion AI must claim the trigger slot at the START of the heal sequence (before initiating the animation) to prevent both companions from simultaneously reading the old count and both firing. If one companion's increment brings `companion_heal_triggers_this_encounter` to `COMPANION_MAX_TRIGGERS`, the second companion's guard check fails and it does not fire.

- **If `COMPANION_MAX_TRIGGERS` for this encounter is already reached**: Companion does not initiate a heal animation regardless of the HP threshold. The trigger check silently fails. Triggers reset at encounter end (all enemies in the current combat group dead, or player enters a new room).

- **If `max_health` changes via `stat_changed` while the player is HEALING**: The heal commit uses `max_health` at commit time. If `max_health` decreases between press and commit, `current_health` is clamped to the new `max_health` before the heal fires — the heal then applies from that lower ceiling.

- **If `max_health` changes via `stat_changed` while the entity is DEAD**: `max_health` is updated immediately. When `respawn()` is called, `current_health = max_health` uses the current post-change value.

- **If `apply_damage` is called with a fractional float value**: Health & Death accepts `int` only. Combat is responsible for rounding `damage_taken` before calling `apply_damage`. Passing a float is a caller error, not silently rounded here.

- **If `apply_damage` and `apply_heal` both run in the same physics frame** (e.g., an enemy hit and a companion heal resolve in the same tick): Each call evaluates the `was_critical` flag independently in sequence. If `apply_damage` puts the player into critical (`was_critical` changes false→true, `critical_health_entered` fires), and then `apply_heal` exits critical in the same frame (`was_critical` changes true→false, `critical_health_exited` fires), both signals fire — this is correct behavior. The `was_critical` flag ensures each signal fires exactly once per threshold crossing regardless of call order. There is no scenario in which a single call can cross the threshold in both directions; each call changes HP in only one direction.

## Dependencies

**Upstream (this system depends on):**

| System | What we need | Interface |
|--------|-------------|-----------|
| **Character Stats** | `max_health` at spawn and on updates | Read on init; subscribe to `stat_changed("max_health")` |

**Downstream (these systems depend on Health & Death):**

| System | What they need | Interface |
|--------|----------------|-----------|
| **Combat** | `apply_damage(amount: int)` to apply pre-calculated damage | Direct call |
| **Checkpoint & Respawn** | `respawn(position)` to restore HP and exit DEAD state; `refill_charges()` on checkpoint touch | Direct call |
| **Companion AI** | `current_health`, `max_health` to decide heal timing; `apply_heal(amount)` to deliver companion heal | Read-only + direct call |
| **HUD** | `health_changed`, `critical_health_entered`, `critical_health_exited`, `died` signals for HP bar display | Signal subscription |
| **Audio** | `critical_health_entered` for low-health audio cue; `died` for death sound | Signal subscription |
| **Input & Controls** (via InputResolver) | Heal action guard: `current_heal_charges == 0` check; DEAD/HEALING state check | Direct property read |
| **Stagger System** | Whether entity is alive (enemies only) — reads `current_health > 0` | Read-only |
| **Enemy AI** | Player `current_health` for threat assessment; entity `died` signal to remove from combat | Signal + read-only |
| **Tutorial & Onboarding** | `current_health / max_health` for first-critical-health detection | Read-only |

**Cross-document coordination required:**
- **Movement GDD** must add a HEALING state that suppresses `velocity.x` for `HEAL_DURATION`, with immediate transition to HIT_STUN on `apply_damage` before `HEAL_COMMIT_TIME`. This state is not currently in the Movement GDD — coordination required before Movement implementation stories are picked up.
- **Combat GDD** must confirm it calls `apply_damage(int)` with a fully pre-calculated value (post-defense, post-type-reduction). Never pass floats or raw attack values directly to Health & Death.
- **Companion AI GDD** must read `COMPANION_HEAL_THRESHOLD`, `COMPANION_HEAL_COOLDOWN`, and `COMPANION_MAX_TRIGGERS` from Health & Death (not hardcode them internally) and call `player.apply_heal()` — never modify `current_health` directly. Companion heals are instantaneous and uninterruptible; Companion AI GDD does not need to define a heal commit window. Companion AI must also guard against initiating a heal while the player is in HEALING state (check before starting the animation) and must claim the trigger slot atomically at the start of the heal sequence.
- **Enemy AI GDD** must guarantee a minimum gap of ≥ 0.80s between attack sequences in any encounter where Estus healing is the intended player solution. Without this contract, enemies may chain attacks faster than `HEAL_COMMIT_TIME`, making healing non-viable and undermining the healing-as-decision player fantasy.
- **Input & Controls GDD** must reserve a heal action binding and specify whether the heal action is bufferable (recommended: non-bufferable, like jump — direct polling).
- **HUD GDD** must implement `critical_health_entered`/`critical_health_exited` visual feedback (pulsing HP bar, color shift at ≤20% HP).

## Tuning Knobs

| Knob | Location | Current Value | Safe Range | Too High → | Too Low → |
|------|----------|---------------|-----------|------------|-----------|
| `HEAL_CHARGES_BASE` | §3 Estus Healing | 3 | 1–6 | Healing resource trivializes encounter damage; players never fear running out | Single charge punishes too harshly; one mistimed use can strand the player for the rest of an encounter |
| `HEAL_PERCENT` | Formula 1 | 0.40 (40%) | 0.20–0.70 | Single heal recovers from too many hits; damage pressure collapses | Heal is negligible; players prefer to push on rather than spend the animation window |
| `HEAL_COMMIT_TIME` | §3 Estus Healing | 0.50s | 0.20–0.80 | Heal fires so late that enemy follow-up hits nearly always cancel it; healing becomes non-viable | Heal fires almost instantly; commitment risk disappears and fake-out heals trivialize encounters |
| `HEAL_DURATION` | §3 Estus Healing | 1.0s | 0.60–1.50 | Long animation lock leaves the player exposed too long after a safe heal window | Animation ends too quickly; the heal action loses visual weight and blurs with normal movement. **Post-commit note:** at 1.0s total with commit at 0.50s, the player is locked for 0.50s after HP is restored with no risk/reward to evaluate ("dead zone"). Internal playtesting should verify this feels acceptable. Candidates: HEAL_DURATION=0.70–0.75s (reduces post-commit lock to 0.20–0.25s) or HEAL_COMMIT_TIME=0.35s. |
| `CRITICAL_THRESHOLD` | §6 Critical Health | 0.20 (20%) | 0.10–0.35 | Critical state triggers too frequently; the warning becomes noise | Triggers only at near-death; player has no warning window to respond before dying |
| `COMPANION_HEAL_THRESHOLD` | §4 Companion Healing | 0.18 (18%) | 0.10–0.25 | Companion heals above critical zone, eliminating the fear arc — player never reaches critical state when a Healer is available (see interaction warning below) | Threshold too low; companion fires only at extreme near-death, rarely in time before the kill |
| `COMPANION_HEAL_PERCENT` | Formula 2 | 0.30 (30%) | 0.15–0.50 | Companion heal recovers too much; Healer presence trivializes the damage budget | Heal is negligible; the rescue moment emotional impact is undercut by an irrelevant HP delta |
| `COMPANION_HEAL_COOLDOWN` | §4 Companion Healing | 20.0s | 10–45s | Cooldown so long companion almost never heals in practice; Pillar 3 moments rarer than intended | Companion heals every few seconds; encounter damage budget becomes meaningless |
| `COMPANION_MAX_TRIGGERS` | §4 Companion Healing | 2 per encounter | 1–4 | Companion heals so frequently per encounter that the player always survives | Too restrictive in long boss encounters where 1 trigger may be insufficient |

**Interaction warnings:**
- `HEAL_PERCENT` and `HEAL_CHARGES_BASE` must be tuned together — low percent with high charges (many small heals) creates a different feel than high percent with few charges (rare but significant heals), even at the same total HP recovery ceiling.
- `COMPANION_HEAL_THRESHOLD` and `COMPANION_HEAL_PERCENT` interact: if `COMPANION_HEAL_THRESHOLD` is raised above `CRITICAL_THRESHOLD (0.20)`, the companion heals the player BEFORE they enter critical state — eliminating the fear arc entirely when a Healer companion is present. `COMPANION_HEAL_THRESHOLD` must remain ≤ `CRITICAL_THRESHOLD` to preserve the intended fear-peak rescue sequence. The current default (0.18) is designed to be just inside the critical zone.
- `COMPANION_HEAL_THRESHOLD` and `COMPANION_HEAL_PERCENT` also interact on recovery amount: a threshold of 0.18 with heal of 30% brings the player from 18% → 48% HP — enough to survive, not enough to feel safe. If `COMPANION_HEAL_PERCENT` is raised above 0.50, the player lands above 68% from a rescue — well above danger. Tune these together.
- `HEAL_PERCENT` at the safe range upper bound (0.70) is degenerate for endgame: Lv60 Warrior gets 1155 HP/charge × 3 = 3,465 total healing against 1,650 max_health. The 0.20–0.70 safe range applies to early-game tuning sessions only; endgame balance should stay near 0.35–0.45.

## Visual/Audio Requirements

Health & Death owns the state events that drive all HP-related feedback, but visual and audio execution belongs to their respective GDDs. The following events require feedback; hooks are listed here for cross-GDD coordination.

**Animation hooks (owned by Animation/Art GDD, triggered by Health & Death signals):**

| Event | Animation Hook | Notes |
|-------|---------------|-------|
| `apply_damage` fires | Player sprite hit-flash (brief damage tint) | Duration TBD — typically 2–4 frames. Owned by Animation GDD. |
| `current_health == 0` → DEAD | Trigger `death` animation | Already specified in Movement GDD DEAD state hook. |
| Estus heal pressed, charges > 0 | Trigger `heal_use` animation (flask raised) | HEAL_DURATION = 1.0s total. Commit point at 0.50s must be visually readable — the flask should be clearly "drinking" before 0.50s so the player understands the commitment window. |
| Estus heal pressed, charges == 0 | Trigger `heal_empty` animation (~0.30s) | Short, distinct from the active heal. Should communicate "nothing there" — a reach-and-fail gesture, not a drinking gesture. |
| Companion heal fires | Companion plays `companion_heal` animation; player receives `heal_received` VFX | Companion AI owns the companion animation. Health & Death fires no signal; Companion AI calls `apply_heal()` directly. |
| `critical_health_entered` | HP bar pulses / color shift | HUD GDD owns the bar. Health & Death fires the signal; HUD implements the effect. |

**Sound hooks (owned by Audio Design GDD, triggered by Health & Death events):**

| Event | Sound Cue | Notes |
|-------|-----------|-------|
| `critical_health_entered` | Low-health ambient tone begins (heartbeat or tension drone) | Loops while in critical state; `critical_health_exited` stops it. |
| `critical_health_exited` | Low-health tone fades out | On any heal that exits critical state. |
| Estus heal commit (0.50s) | Flask drink sound (liquid/gulp) | Plays at commit point, not at press. |
| `heal_empty` animation plays | Empty flask sound (hollow clink, no liquid) | Distinct from the active drink sound — immediate feedback that nothing was consumed. |
| `died` signal | Death sound / character audio | Audio GDD owns the specific cue. |

> **📌 Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:health-and-death` to produce per-animation frame counts, sprite sheet specs, and visual descriptions from this section.

## UI Requirements

Health & Death has no dedicated UI screens. All HP-related UI surfaces are owned by the HUD GDD. The following are the data contracts Health & Death provides that HUD depends on:

- **HP Bar**: HUD reads `current_health` and `max_health` via `health_changed` signal. Fill ratio = `current_health / max_health`. Display format and animation owned by HUD.
- **Critical health visual**: HUD subscribes to `critical_health_entered` / `critical_health_exited` to trigger pulsing/color shift at ≤20% HP. Signal timing owned here; visual implementation owned by HUD.
- **Estus charge counter**: HUD reads `current_heal_charges` and `HEAL_CHARGES_BASE`. Display format (pip icons, number, etc.) owned by HUD.
- **Empty-flask feedback**: The `heal_empty` animation is a character animation (Animation GDD), not a UI element. HUD may optionally flash the charge counter on empty use — HUD GDD decision.

> **📌 UX Flag — Health & Death**: Run `/ux-design` in Phase 4 (Pre-Production) for the HUD screen to specify HP bar layout, Estus charge display, and critical health visual before writing implementation epics. Stories referencing these UI elements should cite `design/ux/hud.md`, not this GDD directly.

## Acceptance Criteria

*Story Type: Logic — all criteria require passing automated unit tests in `tests/unit/health-and-death/` before any implementing story is marked Done.*
*Timer-dependent tests (marked ⏱) must mock the timer using `create_timer` or an injected delta accumulator — wall-clock waits are non-deterministic in GUT.*

### HP Tracking

**AC-HP-01** — GIVEN a character spawns, WHEN initialization completes, THEN `current_health == max_health`.

**AC-HP-02** — GIVEN `current_health` is at any value, WHEN `apply_damage` or `apply_heal` is called with an amount that would push health outside `[0, max_health]`, THEN `current_health` is clamped and never exceeds `max_health` or falls below `0`.

### apply_damage

**AC-DMG-01** — GIVEN a living character with `current_health = 50`, WHEN `apply_damage(0)` or `apply_damage(-5)` is called, THEN `current_health` remains `50` and no signals are emitted.

**AC-DMG-02** — GIVEN a living character with `current_health = 50`, WHEN `apply_damage(20)` is called, THEN `current_health == 30`, `health_changed(50, 30)` is emitted, and `died` is not emitted.

**AC-DMG-03** — GIVEN a living character with `current_health = 10`, WHEN `apply_damage(50)` is called, THEN `current_health == 0`, `health_changed(10, 0)` is emitted, and `died` is emitted.

**AC-DMG-04** — GIVEN the character is in DEAD state, WHEN `apply_damage(30)` is called, THEN `current_health` is unchanged and no signals are emitted.

### Estus Healing

**AC-ESTUS-01** — GIVEN a character spawns, WHEN initialization completes, THEN `current_heal_charges == 3`.

**AC-ESTUS-02** — GIVEN the character is DEAD or already HEALING, WHEN the player triggers Estus, THEN action is a no-op: `current_heal_charges` and `current_health` are unchanged.

**AC-ESTUS-03** — GIVEN `current_heal_charges == 0`, WHEN the player triggers Estus, THEN `heal_empty_triggered` signal is emitted, `current_health` is not restored, and `current_heal_charges` remains `0`.

**AC-ESTUS-04** ⏱ — GIVEN a Lv1 Warrior (`max_health = 105`) with at least 1 charge and `current_health < 105`, WHEN the player triggers Estus and `HEAL_COMMIT_TIME (0.50s)` elapses without interruption (advance timer via mock), THEN `current_health` increases by `42` (clamped to `max_health`) and `current_heal_charges` is decremented by `1`.

**AC-ESTUS-05** ⏱ — GIVEN a healing sequence is in progress and `HEAL_COMMIT_TIME` has not elapsed, WHEN `apply_damage` is called before `0.50s`, THEN heal is cancelled, `current_health` is not restored, and `current_heal_charges` is still decremented by `1` (charge was committed on press).

**AC-ESTUS-06** ⏱ — GIVEN a healing sequence is in progress and `HEAL_COMMIT_TIME` has elapsed (0.50s passed), WHEN `apply_damage` is called before `HEAL_DURATION (1.0s)`, THEN HP restoration stands and damage applies on top of it normally.

**AC-ESTUS-07** — GIVEN `current_heal_charges < 3`, WHEN `refill_charges()` is called, THEN `current_heal_charges == 3`.

### Companion Healing

**AC-COMP-01** — GIVEN `float(current_health) / float(max_health) ≤ COMPANION_HEAL_THRESHOLD (0.18)`, cooldown expired, trigger count `< 2`, and player is NOT in HEALING state, WHEN the companion heal evaluates, THEN `apply_heal(round(max_health × COMPANION_HEAL_PERCENT))` is applied to the Lv1 Warrior player (`round(105 × 0.30) = 32`) and trigger count increments by `1`.

**AC-COMP-02** — GIVEN trigger count `== 2`, WHEN `current_health / max_health ≤ 0.40`, THEN companion heal does not trigger and trigger count remains `2`.

**AC-COMP-03** ⏱ — GIVEN a companion heal just fired, WHEN fewer than `20.0s` have elapsed (mock timer), THEN a second companion heal does not trigger even if the health threshold is met.

### Death & Respawn

**AC-DEATH-01** — GIVEN `current_health` reaches `0` and DEAD state is entered, WHEN `apply_heal(50)` is called, THEN it is a no-op and `current_health` remains `0`.

**AC-DEATH-02** — GIVEN the character is DEAD, WHEN `respawn()` is called, THEN DEAD state exits and `current_health == max_health`.

### Critical Health Threshold

**AC-CRIT-01** — GIVEN `current_health / max_health > 0.20`, WHEN damage reduces the ratio to `≤ 0.20`, THEN `critical_health_entered` emits exactly once.

**AC-CRIT-02** — GIVEN `current_health / max_health ≤ 0.20`, WHEN healing raises the ratio above `0.20`, THEN `critical_health_exited` emits exactly once.

**AC-CRIT-03** — GIVEN `current_health / max_health` is already `≤ 0.20`, WHEN additional damage is taken without crossing back above the threshold, THEN `critical_health_entered` does not emit again.

### max_health Changes

**AC-MAXHP-01** — GIVEN `current_health = 80` and `max_health = 100`, WHEN `max_health` is set to `60`, THEN `current_health` is immediately clamped to `60`.

**AC-MAXHP-02** — GIVEN `current_health = 80` and `max_health = 100`, WHEN `max_health` is set to `100` or higher, THEN `current_health` remains `80`.

### Formula Spot-Checks

**AC-FORM-01** — GIVEN `max_health = 105`, WHEN `HEAL_AMOUNT` is computed, THEN result = `round(105 × 0.40) = 42` (verified by AC-ESTUS-04).

**AC-FORM-02** — GIVEN `max_health = 105`, WHEN `COMPANION_HEAL_AMOUNT` is computed, THEN result = `round(105 × 0.30) = 32` (verified by AC-COMP-01).

## Open Questions

1. **Heal action input binding** — the heal action is reserved in Input & Controls GDD but no binding has been assigned. Owner: Input & Controls GDD. Must be resolved before Input & Controls stories are implemented.

2. **"Encounter" boundary for `COMPANION_MAX_TRIGGERS`** — the spec says triggers reset "when all enemies in the current combat group are dead, or the player enters a new room." The precise definition of a "combat group" and a "room" depends on Scene Management GDD. Owner: Scene Management GDD / Enemy AI GDD. Resolve before Companion AI stories are authored.

3. **Enemy HP values** — this GDD defines the HP system but not per-enemy HP values. Enemy HP is instance-level configuration owned by Enemy AI GDD (one `max_health` per enemy type). Owner: Enemy AI GDD.

4. **HEALING state in Movement GDD** — Movement GDD currently has no HEALING state. This state must be added before Movement implementation stories are picked up. Owner: Next Movement GDD revision. (See Dependencies cross-doc coordination note.)
