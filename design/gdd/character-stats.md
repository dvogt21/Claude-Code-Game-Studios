# Character Stats

> **Status**: Revised (post design-review 2026-05-31)
> **Author**: Design session + agents
> **Last Updated**: 2026-05-31
> **Implements Pillar**: Foundation — all four pillars depend on this system's definitions
> **Layer**: Foundation | **Priority**: MVP | **Design Order**: #1

## Overview

Character Stats is the numerical vocabulary of Ashen Maple — the complete set of named properties that define what every entity in the game can do and how much it can endure. At the player-facing level, stats are how survivability, aggression, and mobility are measured: max health determines how many hits you survive, stamina determines how often you can dodge and parry, attack and defense govern damage exchange, movement speed shapes positioning, and poise determines how hard you are to interrupt. Players encounter this system directly when selecting a class, reading gear comparison tooltips, and watching their character grow more capable across levels. At the infrastructure level, this system defines the stat schema — the authoritative list of stat names, their value types, valid ranges, and composition rules — that every downstream system (Health & Death, Stamina, Combat, Movement, Stagger) reads without reinventing. Nothing in this game computes a number about a character's capability without referencing a stat defined here.

## Player Fantasy

When a player opens the character stat screen, they should feel two things simultaneously: *this is who I am* and *look how far I've come.*

The first feeling is class identity. A Warrior's stat screen has high HP and formidable attack — it looks like a fighter. A Mage's screen has a smaller health pool and a different attack profile — it looks like a glass cannon. The numbers aren't just values; they're the numerical portrait of a character type. From the moment of class selection, the stat screen should make the player feel that their choice was meaningful and distinct.

The second feeling is the arc of *Fear Becomes Confidence* (Pillar 2) made measurable. When a new player dies to the Armored Knight for the fifth time, their stats are a blunt statement of fragility. When that same player, twenty hours later, opens the same screen after a full gear enhancement pass and two job advancements, the numbers are proof of transformation. The stat screen is where the progression system's emotional promise is kept — not just "you unlocked a skill," but "you are quantifiably more capable than you were."

Stats are also a communication layer for the game's risk/reward vocabulary. A player reading their stamina max instinctively understands how many dodges they get before they're exposed. A player reading their poise understands how aggressive they can be before an enemy can stagger them mid-combo. Stats are not abstract numbers — they are the player's operational briefing before every fight.

## Detailed Design

### Core Rules

**1. Two Tiers of Stats**

Ashen Maple uses a two-tier stat model:

**Tier 1 — Primary Attributes** (player-invested): STR, DEX, INT, LUK. These are the four numbers players grow by spending Ability Points. They are the root values that derived stats compute from. Players feel the stat screen primarily through these four numbers.

**Tier 2 — Derived Stats and Direct Stats**: Values computed from primary attributes (attack, max_health, defense, max_stamina, move_speed, critical_chance, magic_damage_reduction, drop_rate_bonus) or set directly by class/level/gear without flowing through primary attributes (poise, stagger_power, timing stats).

---

**2. Primary Attributes**

| Attribute | Symbol | Description | Primary Class |
|-----------|--------|-------------|---------------|
| Strength | `STR` | Physical force. Drives Warrior attack. Also increases max_health and defense. | Warrior |
| Dexterity | `DEX` | Speed and finesse. Drives Thief and Archer attack. Also increases max_stamina and move_speed. | Thief, Archer |
| Intelligence | `INT` | Arcane mastery. Drives Mage attack. Also increases magic_damage_reduction. | Mage |
| Luck | `LUK` | Fortune. Contributes to all class attack formulas (secondary). Increases critical_chance and drop_rate_bonus. | Secondary (all) |

Primary attributes follow the full composition rule from Section 7:
`final_ATTR = (beginner_base + job_boost + AP_invested + flat_ATTR_bonus_from_gear) × multiplier_ATTR`

- **`beginner_base`**: The Beginner starting value (STR=DEX=INT=LUK=4). Tracked separately.
- **`job_boost`**: The one-time class boost applied at job advancement (e.g., Warrior +20 STR). Tracked separately.
- **`AP_invested`**: Cumulative AP spent into this attribute. Tracked separately.
- **`flat_ATTR_bonus_from_gear`**: Flat attribute bonuses from equipped gear (e.g., "Ring of Strength +5 STR").
- **`multiplier_ATTR`**: Additive sum of buff/skill multipliers targeting this attribute (e.g., a "+20% STR" buff: multiplier = 1.20). Defaults to 1.0 when no buffs are active.

The three internal fields (`beginner_base`, `job_boost`, `AP_invested`) are stored separately to enable the Stat Screen's three-layer breakdown display (base / gear / buff layers). The Section 2 shorthand `base_ATTR + AP_invested + flat_bonus` describes the no-buff, no-gear case only.

When a primary attribute changes, all derived stats that depend on it recompute immediately.

---

**3. Ability Point System**

- Every character level-up grants **5 AP** to distribute freely among STR, DEX, INT, LUK
- Each AP point invested adds 1 to the chosen attribute
- No AP can be reallocated after assignment (permanent — same as MapleStory)
- Each class has a **recommended AP distribution per level** shown in the UI; the player may follow it or diverge at the cost of suboptimal primary stat growth

| Class | Recommended AP distribution (per level) |
|-------|------------------------------------------|
| Beginner | Player decides freely |
| Warrior | 4 STR, 1 DEX |
| Thief | 3 DEX, 2 LUK |
| Archer | 4 DEX, 1 STR |
| Mage | 4 INT, 1 LUK |

**Enforcement**: Gear stat requirements (defined in Inventory & Equipment GDD) mechanically enforce secondary stat investment. Weapons and armor carry minimum attribute thresholds — a character who deviates significantly from the recommended distribution may be unable to equip tier-appropriate gear. This is the primary incentive for following the recommended path. The recommended distribution is the path of least resistance through the equipment progression, not an advisory suggestion.

---

**4. Starting Attribute Values**

All characters begin as Beginner with these base primary attribute values (before any AP investment):

| Attribute | Beginner Base |
|-----------|---------------|
| STR | 4 |
| DEX | 4 |
| INT | 4 |
| LUK | 4 |

At **job advancement (level 10)**, the chosen class applies a permanent one-time primary attribute boost — establishing the class identity at the moment of transformation. These are NOT AP investments; they are applied as `base_ATTR` increases:

| Attribute | Warrior | Thief | Archer | Mage |
|-----------|:---:|:---:|:---:|:---:|
| STR | +20 | — | +5 | — |
| DEX | — | +15 | +20 | — |
| INT | — | — | — | +20 |
| LUK | — | +5 | — | +10 |

*Tuning knobs — to be adjusted during Vertical Slice balancing.*

---

**5. Derived Stats — What Each Primary Attribute Drives**

| Derived Stat | Symbol | Driven By | Notes |
|---|---|---|---|
| Attack | `attack` | Per-class formula (primary stat × weight + LUK + `weapon_att`) | `weapon_att` is a property of the equipped weapon; defined in Inventory & Equipment GDD. **Carries a `damage_type` tag**: `physical` for Warrior/Thief/Archer; `magical` for Mage. The Combat GDD must route damage through the correct reduction formula based on this tag. |
| Max Health | `max_health` | Level + STR | STR contributes HP per point |
| Defense | `defense` | Armor `def_rating` + STR | STR contributes flat damage reduction per point |
| Max Stamina | `max_stamina` | Level + DEX | DEX contributes stamina per point |
| Stamina Regen Rate | `stamina_regen_rate` | DEX | DEX contributes regen rate per point; runtime ticking owned by Stamina GDD |
| Move Speed | `move_speed` | Class base + DEX | DEX contributes world units/s per point |
| Critical Chance | `critical_chance` | LUK | Probability of a 1.5× critical hit. Capped at 80% |
| Drop Rate Bonus | `drop_rate_bonus` | LUK | Additive multiplier to loot drop rolls; consumed by Loot & Drop Tables GDD |
| Magic Damage Reduction | `magic_damage_reduction` | INT | Percentage of magic-type damage absorbed. Capped at 75% |

**Critical hit multiplier** is a game constant: **1.5×** (not a stat). LUK affects the probability; the multiplier is fixed in MVP.

---

**6. Direct Stats — Not Derived from Primary Attributes**

These stats are set by class level tables and gear — not by AP investment.

| Stat | Symbol | Type | Range | Description |
|------|--------|------|-------|-------------|
| Poise | `poise` | int | 0–100 | Animation-interrupt resistance. How many hit-power units an entity absorbs before being staggered mid-action. |
| Stagger Power | `stagger_power` | int | 0–50 | Stagger damage inflicted on enemies per successful hit or parry. Feeds the enemy stagger bar. |
| Stagger Threshold | `stagger_threshold` | int | 0–200 | *(Enemy stat only)* Total stagger damage to trigger stagger break. Defined per enemy type in Enemy AI GDD. Players: 0. |
| Hit Stun Duration | `hit_stun_duration` | float | 0–0.80 s | How long the entity is stuck in hit stun after taking a hit. |
| Parry Window | `parry_window` | float | 0.15–0.60 s | Parry input window. **Base: 0.35 s** (prototype-validated). Gear-modifiable. |
| Dodge I-Frame Duration | `dodge_iframes` | float | 0.10–0.45 s | Invulnerability frame duration during a dodge roll. **Base: 0.22 s**. Gear-modifiable. |
| Dodge I-Frame Delay | `dodge_iframes_delay` | float | 0.03–0.15 s | Delay before I-frames activate at the start of a dodge. **Base: 0.08 s**. Gear-modifiable. |

---

**7. Composition Rule**

All final stat values follow:

`final_value = (base_value + flat_bonus_total) × multiplier_total`

- **Primary attributes**: `base_value` = `beginner_base + job_boost + AP_invested`; `flat_bonus_total` = flat gear bonuses to this attribute; `multiplier_total` = 1.0 + sum of all additive buff/skill percentages targeting this attribute (e.g., two +10% STR buffs → 1.20)
- **Derived stats**: `base_value` = derivation formula result using final composed primary attributes; `flat_bonus_total` = gear bonuses targeting the derived stat directly; `multiplier_total` = buff/skill multipliers
- **Direct stats**: `base_value` = class level table value; `flat_bonus_total` = gear bonuses; `multiplier_total` = buff/skill multipliers

**Signal contract — per-stat model**: Every stat whose value changes during a recompute emits exactly one `stat_changed` signal. A single `recompute_stats()` call that changes STR, max_health, defense, and attack emits four signals, one per changed stat. Stats whose value did not change emit no signal. Downstream systems subscribe to the specific stat names they depend on and react only to those signals. Downstream systems must not cache stat values between frames — always read the current composed value when processing a `stat_changed` signal.

`stat_changed(stat_name: String, old_value: Variant, new_value: Variant)`

---

### States and Transitions

| Event | What changes | Trigger |
|-------|-------------|---------|
| Level-up | 5 AP awarded (not auto-spent — player distributes in stat screen) | XP threshold reached |
| AP invested | `base_ATTR` + 1 for chosen attribute; all dependent derived stats recompute | Player assigns AP |
| Job advancement | One-time class attribute boosts applied to `base_ATTR`; full recompute | Quest gate at level 10 |
| Gear equipped | `flat_bonus_total` updated; all affected stats recompute | Player equips item |
| Gear unequipped | `flat_bonus_total` updated; all affected stats recompute | Player removes item |
| Buff applied | `multiplier_total` updated; affected stats recompute | Skill activation or environmental effect |
| Buff expired | `multiplier_total` updated; affected stats recompute | Duration ends |
| Death / respawn | No stat changes — final stats remain constant | Character HP reaches 0 |

---

### Interactions with Other Systems

| System | Reads from Character Stats | Writes to Character Stats |
|--------|---------------------------|--------------------------|
| **Health & Death** | `max_health`, `defense`, `magic_damage_reduction` | — |
| **Stamina** | `max_stamina`, `stamina_regen_rate` | — |
| **Combat** | `attack`, `poise`, `stagger_power`, `parry_window`, `dodge_iframes`, `dodge_iframes_delay`, `hit_stun_duration` | — |
| **Movement** | `move_speed` | — |
| **Stagger System** | `stagger_power` (player output), `stagger_threshold` (enemy input) | — |
| **Inventory & Equipment** | Provides `weapon_att` input to attack formula | Writes flat bonuses and gear-direct modifiers |
| **Class & Leveling** | — | Writes AP grants on level-up; applies job advancement attribute boosts |
| **Loot & Drop Tables** | — | Reads `drop_rate_bonus` during loot rolls |
| **HUD** | STR, DEX, INT, LUK, all derived stats, all direct stats | — |
| **Enemy AI** | Enemy entity's `attack`, `defense`, `poise`, `stagger_threshold`, `hit_stun_duration`, `move_speed` | — |

## Formulas

All formulas use the composition rule: `final_value = (base_value + flat_bonus_total) × multiplier_total`. Multiplier bonuses are additive with each other before application (two +10% multipliers produce ×1.20, not ×1.21). All stat values referenced are final composed values unless noted.

---

### Formula 1 — Warrior Attack

`warrior_attack = (STR × 4 + DEX) × weapon_att / 100`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Strength (final) | `STR` | int | 4–420 (practical) | Primary offensive stat |
| Dexterity (final) | `DEX` | int | 4–420 (practical) | Secondary stat; accuracy and minor damage |
| Weapon attack rating | `weapon_att` | int | TBD — Inventory & Equipment GDD | Integer attack property of the equipped weapon |
| Output | `warrior_attack` | float | 0–∞ | Raw physical damage before defense |

Output Range: Unbounded; bounded in practice by weapon tier and level cap.

Example:
- Lv1: STR 9, DEX 4, weapon_att 20 → `(36+4)×0.20 = 8.0`
- Lv30: STR 90, DEX 20, weapon_att 80 → `380×0.80 = 304`
- Lv60: STR 200, DEX 40, weapon_att 150 → `840×1.50 = 1260`

Tuning note: Primary-stat weight (4) controls STR dominance — if >5, secondary stat becomes irrelevant; if <3, class identity blurs. `weapon_att / 100` means weapon_att 100 is the 1:1 anchor point — tune weapon tier progression around this.

---

### Formula 2 — Thief Attack

`thief_attack = (DEX × 4 + STR + LUK) × weapon_att / 100`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Dexterity (final) | `DEX` | int | 4–400 | Primary stat |
| Strength (final) | `STR` | int | 4–400 | Secondary stat |
| Luck (final) | `LUK` | int | 4–400 | Secondary stat; also feeds critical chance |
| Weapon attack rating | `weapon_att` | int | TBD — Inventory & Equipment GDD | |
| Output | `thief_attack` | float | 0–∞ | Raw physical damage |

Output Range: Unbounded; slightly lower ceiling than Warrior at equivalent AP because LUK splits the secondary block, but LUK double-dips into crit chance — Thief burst potential comes from crits.

Example:
- Lv1: DEX 9, STR 4, LUK 4, weapon_att 18 → `44×0.18 = 7.9`
- Lv30: DEX 90, STR 15, LUK 30, weapon_att 75 → `405×0.75 = 303.8`
- Lv60: DEX 190, STR 30, LUK 80, weapon_att 140 → `870×1.40 = 1218`

**Thief Class Identity — LUK Triple-Dip (Intentional)**: LUK appears in the Thief attack formula, the crit chance formula (Formula 10), and the drop rate formula (Formula 12). This is intentional. The Thief is Ashen Maple's glass-cannon and economy class: highest burst potential (via crits), best farming efficiency (via drop rate), and competitive expected DPS — offset by the lowest HP pool (no STR investment, no STR health scaling). At Lv100 on the recommended AP distribution, Thief expected DPS slightly exceeds Warrior expected DPS due to crit frequency. This is a design goal, not a balance error. The Thief's weakness is fragility, not damage ceiling.

Tuning note: If LUK feels over-rewarding in this formula, cap its attack contribution (e.g., `min(LUK, 80)`) without touching the crit or drop rate formulas. If Thieves feel too weak vs. Warrior at equal investment, raise to DEX × 4.5.

---

### Formula 3 — Archer Attack

`archer_attack = (DEX × 4 + STR) × weapon_att / 100`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Dexterity (final) | `DEX` | int | 4–400 | Primary stat |
| Strength (final) | `STR` | int | 4–400 | Secondary stat |
| Weapon attack rating | `weapon_att` | int | TBD — Inventory & Equipment GDD | |
| Output | `archer_attack` | float | 0–∞ | Raw physical damage |

Example:
- Lv1: DEX 9, STR 4, weapon_att 19 → `40×0.19 = 7.6`
- Lv30: DEX 90, STR 25, weapon_att 78 → `385×0.78 = 300.3`
- Lv60: DEX 195, STR 50, weapon_att 145 → `830×1.45 = 1203.5`

Tuning note: Archer and Thief share DEX primary; Archer's cleaner formula makes it slightly stronger in raw damage. Differentiate feel through attack speed and range mechanics (range bonus implemented outside this formula), not base damage.

---

### Formula 4 — Mage Attack

`mage_attack = (INT × 4 + LUK) × magic_att / 100`

**Note:** Mage weapons (staves, wands) carry a `magic_att` property, distinct from the physical `weapon_att` property on Warrior/Thief/Archer weapons. These are separate stats defined in the Inventory & Equipment GDD. A physical weapon equipped by a Mage provides `magic_att = 0` — the Mage deals no magical damage from it.

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Intelligence (final) | `INT` | int | 4–400 | Primary stat |
| Luck (final) | `LUK` | int | 4–400 | Secondary stat |
| Magic attack rating | `magic_att` | int | TBD — Inventory & Equipment GDD | Integer magic attack property of the equipped staff/wand |
| Output | `mage_attack` | float | 0–∞ | Raw magical damage before magic damage reduction |

Example:
- Lv1: INT 9, LUK 4, magic_att 18 → `40×0.18 = 7.2`
- Lv30: INT 90, LUK 30, magic_att 76 → `390×0.76 = 296.4`
- Lv60: INT 185, LUK 80, magic_att 148 → `820×1.48 = 1213.6`

Tuning note: If the high-variance LUK-heavy Mage (glass cannon crits) is undesirable, cap LUK's contribution: `min(LUK, 80)`. This limits the secondary contribution without changing the INT primary curve.

---

### Formula 5 — Max Health

`max_health = 50 + (level × 10) + (STR × 5)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base floor | — | int | 50 (constant) | Minimum HP at level 1, no STR |
| Level | `level` | int | 1–100 | Current character level |
| Level scalar | — | int | 10 (tunable) | HP per level regardless of stats |
| Strength (final) | `STR` | int | 4–400 | Primary health driver |
| STR multiplier | — | int | 5 (tunable) | HP per STR point |
| Output | `max_health` | int | 70–∞ | Round to nearest integer |

Example:
- Lv1 Warrior (STR 9): `50 + 10 + 45 = 105 HP` — survives 2–3 hits from a ~30–40 dmg enemy ✓
- Lv1 Mage (STR 4): `50 + 10 + 20 = 80 HP` — survives ~2 hits, intentionally squishier ✓
- Lv30 Warrior (STR 90): `50 + 300 + 450 = 800 HP`
- Lv60 Warrior (STR 200): `50 + 600 + 1000 = 1650 HP`
- Lv60 Mage (STR ~20): `50 + 600 + 100 = 750 HP`

Tuning note: Raise `10` (level scalar) to lift the floor for low-STR classes without touching the STR curve. Raise `5` (STR multiplier) to reward STR investment more; if >8, Warrior becomes unkillable in late game.

---

### Formula 6 — Defense

`defense = (STR × 0.5) + armor_def_rating`

`damage_taken = max(1, raw_damage − defense)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Strength (final) | `STR` | int | 4–400 | Passive toughness |
| STR multiplier | — | float | 0.5 (tunable) | Defense per STR point |
| Armor defense rating | `armor_def_rating` | int | TBD — Inventory & Equipment GDD | Flat defense from equipped armor; 0 if unarmored |
| Output | `defense` | float | 2–∞ | Flat damage reduction |
| Damage taken | `damage_taken` | int | ≥1 | Minimum 1 ensures damage always registers |

Example:
- Lv1: STR 9, armor def_rating 5 → defense 9.5 → 30 raw → 20.5 taken (32% reduction) ✓
- Lv30: STR 90, def_rating 60 → defense 105 → 300 raw → 195 taken (35%)
- Lv60: STR 200, def_rating 150 → defense 250 → 1260 raw → 1010 taken (20%)

Tuning note: Flat defense is naturally regressive against late bosses — this is intentional (Soulslike feel). If mid-game feels invincible, reduce STR multiplier. If defense feels meaningless at high levels, add a percentage-reduction layer on top (coordinate with Combat GDD to avoid interaction with magic_damage_reduction creating stacking invulnerability).

---

### Formula 7 — Max Stamina

`max_stamina = 50 + (level × 1) + (DEX × 0.5)`

Stamina action costs (prototype-validated):
- Dodge roll (0.22s I-frames): **20 stamina**
- Shield parry (0.35s window): **25 stamina**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base floor | — | int | 50 (constant) | |
| Level | `level` | int | 1–100 | |
| Level scalar | — | float | 1 (tunable) | |
| Dexterity (final) | `DEX` | int | 4–400 | Primary stamina driver |
| DEX multiplier | — | float | 0.5 (tunable) | Stamina per DEX point |
| Output | `max_stamina` | float | 52–∞ | Round to nearest integer |

Example:
- Lv1 Thief (DEX 9): `50 + 1 + 4.5 ≈ 56` — 2 dodges (40) + barely a parry ✓
- Lv1 Warrior (DEX 4): `50 + 1 + 2 = 53` — 2 dodges then exposed ✓
- Lv30 Thief (DEX 90): `50 + 30 + 45 = 125` — ~6 dodges
- Lv60 high-DEX Thief (DEX 200): `50 + 60 + 100 = 210` — ~10 dodges

Tuning note: Level scalar is low (1) intentionally — pool growth comes from DEX, not levels. Raise `base floor` if all classes feel too stamina-starved; tune `DEX multiplier` alongside Formula 8 (regen) to prevent DEX builds from trivializing the stamina system.

---

### Formula 8 — Stamina Regen Rate

`stamina_regen = 20 + (DEX × 0.01)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base regen | — | float | 20 (tunable) | Stamina/s at zero DEX investment |
| Dexterity (final) | `DEX` | int | 4–400 | Accelerates recovery |
| DEX coefficient | — | float | 0.01 (tunable) | Stamina/s per DEX point |
| Output | `stamina_regen` | float | ~20–22/s (practical) | Applied while not spending stamina |

Output Range: Minimum ~20/s (base DEX). At Lv60 high-DEX (DEX 200): `20 + 2.0 = 22/s`. Intentionally modest — the DEX stamina payoff is pool size, not regen speed.

Example:
- Lv1 Warrior (DEX 4): 20/s → after 2 dodges (40 stamina from 53), full recovery in ~2 seconds
- Lv60 Thief (DEX 200): 22/s → pool 210, full recovery from empty ~9.5s; stamina remains a constraint

**Regen lockout (resolved from Open Question #2)**: Stamina regeneration begins after a **1.0-second delay** following the last stamina-costing action. During this lockout window, no stamina is recovered. This is tracked as a system constant: `stamina_regen_lockout_delay = 1.0 s`. Runtime enforcement is owned by the Stamina GDD. The lockout creates meaningful commitment cost for each dodge or parry — a player cannot spam two dodges and immediately begin regenerating; they must survive the lockout window first.

Tuning note: If regen feels too punishing at low DEX, raise `base regen` (not the coefficient). If high-DEX makes stamina trivial, lower the coefficient to 0.005. The lockout delay (1.0 s) is the primary lever for combat pacing — reduce to 0.5 s to ease stamina pressure, raise to 1.5 s to increase commitment cost.

---

### Formula 9 — Move Speed

`move_speed = clamp(class_base_speed + (DEX × 0.05), class_base_speed, class_base_speed + 15)`

| Class | `class_base_speed` | Max (capped) |
|-------|-------------------|-------------|
| Warrior | 120 u/s | 135 u/s |
| Mage | 125 u/s | 140 u/s |
| Archer | 135 u/s | 150 u/s |
| Thief | 145 u/s | 160 u/s |

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Class base | `class_base_speed` | float | 120–145 | Per class; tuning knob |
| Dexterity (final) | `DEX` | int | 4–400 | Speed driver |
| DEX coefficient | — | float | 0.05 (tunable) | u/s per DEX point |
| Cap | — | float | class_base + 15 | Prevents geometry exploits |
| Output | `move_speed` | float | 120–160 (clamped) | |

Example:
- Lv1 Thief (DEX 9): `145 + 0.45 = 145.45` — nearly base; class identity, not yet stat-driven
- Lv30 Thief (DEX 90): `145 + 4.5 = 149.5` vs Warrior `120 + (20×0.05) = 121` — Thief clearly faster
- Cap triggers for Thief at DEX 300 (extreme), Warrior at DEX 300 — both require total DEX dedication

Tuning note: Speed differences feel larger in play than on paper — verify through playtesting. If classes feel too similar early, raise `class_base_speed` differences rather than the coefficient. Coordinate cap value with level designers to ensure no speed breaks intended level geometry.

---

### Formula 10 — Critical Hit Chance

`crit_chance = min(0.80, 0.02 + (LUK × 0.0025))`

Critical hit multiplier: **1.5× damage** (fixed game constant).

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base floor | — | float | 0.02 (2%) | Minimum crit; rare flavour without LUK |
| Luck (final) | `LUK` | int | 4–400 | Primary crit driver |
| LUK coefficient | — | float | 0.0025 (tunable) | Crit chance per LUK point |
| Cap | — | float | 0.80 (80%) | Hard ceiling |
| Output | `crit_chance` | float | 0.02–0.80 | Probability of a 1.5× crit |

Example:
- LUK 20 (baseline): `0.02 + 0.05 = 7%` — rare flavour ✓
- LUK 80 (moderate Thief): `0.02 + 0.20 = 22%` — frequent but not dominant ✓
- LUK 120 (dedicated): `0.02 + 0.30 = 32%` — clearly rewarded
- LUK 312+ (cap): 80%

Tuning note: 25% crit is reached at LUK 92 — achievable mid-game for a dedicated build. If crits feel too common, raise threshold by reducing coefficient to 0.002. If the 80% cap feels oppressive, reduce it independently without touching the coefficient.

---

### Formula 11 — Magic Damage Reduction

`magic_reduction = min(0.75, INT × 0.002)`

`magic_damage_taken = raw_magic_damage × (1 − magic_reduction)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Intelligence (final) | `INT` | int | 4–400 | Magic resistance driver |
| INT coefficient | — | float | 0.002 (tunable) | Fraction of magic damage reduced per INT |
| Cap | — | float | 0.75 (75%) | Hard ceiling |
| Output | `magic_reduction` | float | 0.008–0.75 | |

Example (enemy spell: 500 raw magic):
- Warrior (INT 4): 0.8% → 496 taken — nearly unprotected; magic is a serious threat ✓
- Lv30 Mage (INT 90): 18% → 410 taken — meaningful but not dominant ✓
- Lv60 Mage (INT 185): 37% → 315 taken — Mage noticeably resilient to late magic ✓
- Cap (INT 375): 75% → 125 taken

Tuning note: At 0.002/INT, a mid-game Mage (INT 90) has 18% reduction. If raised above 0.004, mid-game Mage reaches 36% — erosion of "magic is threatening" feel. Raise boss magic output rather than lowering this coefficient if late-game feels too safe.

---

### Formula 12 — Drop Rate Bonus

`drop_rate_bonus = LUK × 0.002`

`effective_drop_rate = min(1.0, base_drop_rate × (1 + drop_rate_bonus))`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Luck (final) | `LUK` | int | 4–400 | |
| LUK coefficient | — | float | 0.002 (tunable) | Drop rate multiplier per LUK |
| Output | `drop_rate_bonus` | float | 0–0.60+ | Additive multiplier to base drop rate |

Example (base rare: 2% drop rate):
- LUK 4 (base): `×1.008` → 2.016% — negligible
- LUK 60: `×1.12` → 2.24% — small but perceptible over sessions
- LUK 150 (dedicated Thief): `×1.30` → 2.60% — +30%, meaningful without trivializing
- LUK 300 (max practical): `×1.60` → 3.20%

Tuning note: Benefits show in aggregate, not per-kill. `base_drop_rate` (defined in Loot & Drop Tables GDD) is the primary scarcity lever; this formula scales it proportionally. Tune LUK coefficient in tandem with base rates.

---

### Cross-System Flags (Registry Candidates)

The following values defined here are referenced by multiple systems:

- `weapon_att` — physical weapon property; defined in Inventory & Equipment GDD. Used by Warrior, Thief, Archer attack formulas.
- `magic_att` — magical weapon property (staves/wands only); defined in Inventory & Equipment GDD. Used by Mage attack formula exclusively. Physical weapons have `magic_att = 0`.
- `armor_def_rating` — armor property; defined in Inventory & Equipment GDD.
- `base_drop_rate` — per-item rate defined in Loot & Drop Tables GDD; this formula multiplies it.
- `crit_multiplier = 1.5` — fixed constant; if any future system modifies crit multiplier (e.g., a skill), it must compose through the multiplier layer, not modify this constant.
- Timing constants (`parry_window = 0.35s`, `dodge_iframes = 0.22s`, `dodge_iframes_delay = 0.08s`) — locked from prototype; referenced in stamina cost targets above.

## Edge Cases

- **If `weapon_att = 0` (unarmed or weapon unequipped)**: attack output is 0 for all classes. The player deals 0 physical damage. No bare-fist option exists in MVP — the player always starts with a starter weapon equipped.

- **If any primary attribute is modified during a mid-action** (e.g., a buff applied during an attack animation): the stat change is queued and applied at the next frame boundary. In-flight attack damage uses the attack value at the moment the hit was registered, not the post-buff value.

- **If AP investment pushes a primary attribute above 420 (practical ceiling at Lv100 on recommended AP distribution)**: accept the investment without capping the attribute. Derived stats with hard caps (crit_chance at 80%, magic_damage_reduction at 75%, move_speed at class_base + 15) apply their caps at the output stage, not by clamping the input attribute.

- **If `max_health` decreases (debuff, gear unequip) while current HP exceeds the new max**: current HP is clamped to the new max_health immediately. HP does not go negative.

- **If `max_stamina` decreases while current stamina exceeds the new max**: current stamina is clamped to new max_stamina immediately.

- **If `defense` ≥ `raw_damage`**: `damage_taken = 1`. Damage is never fully negated — a minimum of 1 HP is always dealt. Defense cannot create invincibility.

- **If a hit is both physical and affected by magic_damage_reduction** (two separate damage types landing simultaneously, e.g., an elemental physical strike): apply defense to the physical component and magic_damage_reduction to the magic component independently, then sum. The two reduction systems do not apply to the same damage pool.

- **If `crit_chance` is 80% and a non-crit is rolled**: the hit deals normal damage. No system can override the crit check to guarantee a crit except a skill that bypasses the formula entirely — that bypass is a Skills & Abilities GDD concern.

- **If a critical hit × 1.5 would exceed a damage cap defined in Combat GDD**: apply the crit multiplier first, then apply the cap. Crit does not guarantee uncapped damage.

- **If a companion has `max_stamina = 0` and something attempts to drain its stamina**: the request is a no-op. Systems must check `max_stamina > 0` before applying stamina costs. No error is raised.

- **If gear unequip mid-combat causes a derived stat to drop below a movement system threshold** (e.g., move_speed drops to class_base): the change applies immediately. Movement GDD must handle any `move_speed ≥ class_base_speed` without error — this is a dependency contract.

- **If `effective_drop_rate` (base × LUK bonus) exceeds 1.0**: clamp to 1.0. A 100% drop rate (item always drops) is acceptable for common items via LUK investment. Rare items must have `base_drop_rate` low enough that max LUK cannot produce 100%.

- **If gear modifies `parry_window` or `dodge_iframes` outside their valid ranges**: composed value is clamped to the range floor or ceiling. Systems reading these stats always receive a value within range.

- **If two multiplier buffs affect the same stat simultaneously**: multipliers are additive before application (two +10% → ×1.20, not ×1.21). This rule applies across all stats in this system — no multiplicative stacking unless explicitly stated in the buff's source GDD.

## Dependencies

**Upstream (this system depends on):** None — Character Stats is a Foundation-layer system with no upstream dependencies.

**Downstream (these systems depend on Character Stats):**

| System | What they need | Interface |
|--------|----------------|-----------|
| Health & Death | `max_health`, `defense`, `magic_damage_reduction` | Read on init and `stat_changed` signal |
| Stamina | `max_stamina`, `stamina_regen_rate` | Read on init and `stat_changed` signal |
| Combat | `attack`, `poise`, `stagger_power`, `parry_window`, `dodge_iframes`, `dodge_iframes_delay`, `hit_stun_duration` | Read on `stat_changed` signal |
| Movement | `move_speed` | Read on `stat_changed` signal |
| Stagger System | `stagger_power` (player output), `stagger_threshold` (enemy input) | Read on `stat_changed` signal |
| Inventory & Equipment | Inputs `weapon_att`, `magic_att`, `armor_def_rating`; reads stat block for gear comparison deltas | Bidirectional: gear writes `flat_bonus`; this system exposes block for comparison |
| Class & Leveling | Writes AP grants and class advancement boosts to `base_ATTR` | Class & Leveling owns the write; this system owns composition |
| Loot & Drop Tables | `drop_rate_bonus` as input multiplier at loot roll time | Read on request |
| HUD | All composed stat values for display | Subscribes to `stat_changed` for live updates |
| Enemy AI | Full stat block for enemy entity instances | Read on spawn; updated via `stat_changed` if buffs apply |

**Cross-document coordination required:**
- **Inventory & Equipment GDD** must define `weapon_att`, `magic_att`, and `armor_def_rating` as item properties and confirm the naming convention matches these formulas. **Critical contract**: Inventory & Equipment GDD must publish a `weapon_att` budget curve specifying anchor values at Lv1, Lv30, Lv60, and Lv100 before any encounter or HP budgeting begins — the attack formulas are linearly sensitive to this value. Gear stat requirements (minimum attributes to equip) must be defined here to enforce the recommended AP distributions.
- **Combat GDD** must confirm `damage_taken = max(1, raw_damage − defense)` as its authoritative physical damage calculation, and must route damage through `defense` vs. `magic_damage_reduction` based on the `damage_type` tag exposed by the `attack` stat (`physical` or `magical`).
- **Loot & Drop Tables GDD** must define `base_drop_rate` per item and acknowledge `drop_rate_bonus` as an external input. **Critical constraint**: Rare items must have `base_drop_rate` low enough that a max-LUK build (LUK ≈ 400, drop_rate_bonus = 0.80) cannot push them to 100%. This means `base_drop_rate < 0.556` for any item intended to remain non-guaranteed. The Loot GDD is responsible for enforcing this; Character Stats provides only the multiplier.
- **Skills & Abilities GDD** must respect a maximum `multiplier_total` per stat when designing skill buffs. A guideline of no more than +60% total multiplier on any single primary attribute is recommended to prevent composition rule explosion at high buff stacks. This constraint must be documented as an ADR or design rule before Skills & Abilities GDD is authored.

## Tuning Knobs

| Knob | Location | Current Value | Safe Range | Too High → | Too Low → |
|------|----------|---------------|-----------|------------|-----------|
| `base_health_per_level` | Formula 5 | 10 HP/level | 5–20 | Low-STR classes become too durable at high levels | Mage feels impossibly fragile; death from single hits |
| `health_per_STR` | Formula 5 | 5 HP/STR | 3–8 | Warrior becomes unkillable late-game | STR investment feels unrewarding; all classes converge |
| `defense_per_STR` | Formula 6 | 0.5 DEF/STR | 0.2–1.0 | Mid-game Warrior feels invincible vs. normal enemies | Defense meaningless even with STR investment |
| `base_stamina_per_level` | Formula 7 | 1 STA/level | 0–3 | Stamina becomes a non-constraint at high levels | Gap between high-DEX and low-DEX builds widens too fast |
| `stamina_per_DEX` | Formula 7 | 0.5 STA/DEX | 0.2–1.0 | High-DEX Thief chains actions indefinitely; stamina system collapses | DEX investment pointless for stamina; all classes converge |
| Dodge cost | Formula 7 reference | 20 STA | 15–30 | Low-pool classes can barely dodge twice | Stamina feels like a non-resource; no risk to repeated dodging |
| Parry cost | Formula 7 reference | 25 STA | 20–35 | Parry rarely attempted; dodge always wins | Parry spammable with no commitment cost |
| `base_regen` | Formula 8 | 20 STA/s | 10–35 | Stamina recovers so fast tension between actions disappears | Recovery feels punishing; players wait too long between engagements |
| `regen_per_DEX` | Formula 8 | 0.01 STA/s/DEX | 0.005–0.05 | High-DEX regen trivializes stamina constraint | DEX regen benefit invisible; secondary payoff disappears |
| `class_base_speed` (Warrior) | Formula 9 | 120 u/s | 100–140 | Indistinguishable from faster classes | Warrior unplayable; unable to reposition |
| `class_base_speed` (Thief) | Formula 9 | 145 u/s | 130–165 | Skips intended geometry; level design must compensate | Loses mobility identity |
| `speed_per_DEX` | Formula 9 | 0.05 u/s/DEX | 0.02–0.10 | Speed cap triggers too early (mid-game); further DEX wasted | Speed difference between classes negligible |
| `move_speed_cap offset` | Formula 9 | +15 u/s above class base | +10–+25 | Extreme DEX breaks level geometry | Cap hit too early; max-DEX build gains nothing from speed |
| `crit_per_LUK` | Formula 10 | 0.0025/LUK | 0.001–0.005 | 25% crit reached too early; crits feel constant | 25% crit requires extreme investment; LUK feels unrewarding |
| `crit_cap` | Formula 10 | 80% | 60–90% | Near-guaranteed crits; encounter balance collapses | Dedicated LUK build never reaches satisfying crit frequency |
| `crit_multiplier` | Global constant | 1.5× | 1.3–2.0 | Crits one-shot at mid-game; burst feels unfair | Crits indistinguishable from normal hits; LUK payoff disappoints |
| `magic_def_per_INT` | Formula 11 | 0.002/INT | 0.001–0.004 | Mid-game Mage resists too much magic; boss magic feels toothless | INT investment provides negligible benefit; effect invisible |
| `magic_def_cap` | Formula 11 | 75% | 60–85% | Mage immune to magic; only physical damage matters | Max INT still takes heavy magic; identity undermined |
| `drop_per_LUK` | Formula 12 | 0.002/LUK | 0.001–0.005 | LUK farming trivializes loot scarcity | LUK drop benefit invisible; players not rewarded |
| Warrior job advancement STR boost | Section C-4 | +20 STR | +10–+30 | Job advancement creates spike; adjacent content trivial | Advancement anticlimactic; class identity feels unearned |
| `AP_per_level` | Global constant | 5 | 3–7 | Players over-invest too quickly; secondary stats inaccessible early | Investment decisions too slow; builds take too long to emerge |

**Interaction warnings (tune these in pairs):**
- `stamina_per_DEX` + `regen_per_DEX` — raising both eliminates stamina as a constraint for high-DEX builds
- `crit_per_LUK` + `crit_multiplier` — high frequency × high multiplier creates burst spikes that break encounter design
- `defense_per_STR` + `health_per_STR` — together determine Warrior effective durability; tuning one without the other shifts the class identity more than either alone

## Visual/Audio Requirements

None direct. Character Stats is a Foundation-layer data system — players experience it through the HUD (HP/stamina bars), Combat (attack/defense resolution), and Class & Leveling (level-up screen). Visual and audio requirements for those outputs are owned by their respective GDDs.

## UI Requirements

Three screens depend on this system. Author UX specs for each in Phase 4 (Pre-Production):

1. **Character Stat Screen** — displays STR, DEX, INT, LUK with current values and contribution breakdown (base / gear / buff layers visible separately), all derived stats (attack, defense, max_health, etc.), and all direct stats (poise, stagger_power, timing stats).
2. **AP Allocation Screen** — shown on level-up. Displays 5 available AP, current attribute values, and the class recommended distribution. Player assigns points and confirms before they are locked.
3. **Gear Comparison Tooltip** — when inspecting a gear item, shows the resulting delta for all affected derived stats (not just weapon_att — show the computed attack change, defense change, etc.).

> **📌 UX Flag — Character Stats**: Run `/ux-design` in Phase 4 to create specs for the Stat Screen, AP Allocation Screen, and Gear Comparison Tooltip before writing epics. Stories referencing these UIs should cite `design/ux/[screen].md`, not this GDD directly.

## Acceptance Criteria

*Story Type: Logic — all criteria must have passing automated unit tests in `tests/unit/stats/` before any implementing story is marked Done.*

### Core Rules

**CR-01** — GIVEN a new character is created with Beginner class and no AP spent, WHEN attributes are read, THEN STR = 4, DEX = 4, INT = 4, LUK = 4.

**CR-02** — GIVEN a character is at level N, WHEN the character levels up to N+1, THEN available AP increases by exactly 5.

**CR-03** — GIVEN a character has spent 3 AP into STR, WHEN `reallocate_ap(from: "STR", to: "DEX", amount: 1)` is called, THEN the function returns `false` (or the GDScript error sentinel), STR retains its value, DEX retains its value, no AP is refunded, and no `stat_changed` signal is emitted.

**CR-04** — GIVEN a Warrior at level 9 with STR = 10, WHEN the character levels up to level 10 and job advancement is applied, THEN STR = 30 (10 + the one-time +20 boost).

**CR-05** — GIVEN a Warrior who has already advanced at level 10, WHEN any subsequent level-up occurs, THEN STR does not receive an additional +20 boost.

**CR-04b** — GIVEN a Thief at level 9 with DEX = 10, LUK = 6, WHEN job advancement is applied at level 10, THEN DEX = 25 (10 + the one-time +15 boost) and LUK = 11 (6 + the one-time +5 boost).

**CR-04c** — GIVEN an Archer at level 9 with DEX = 10, STR = 5, WHEN job advancement is applied at level 10, THEN DEX = 30 (10 + the one-time +20 boost) and STR = 10 (5 + the one-time +5 boost).

**CR-04d** — GIVEN a Mage at level 9 with INT = 10, LUK = 6, WHEN job advancement is applied at level 10, THEN INT = 30 (10 + the one-time +20 boost) and LUK = 16 (6 + the one-time +10 boost).

**CR-05b** — GIVEN a Thief who has already advanced at level 10, WHEN any subsequent level-up occurs, THEN DEX does not receive an additional +15 boost and LUK does not receive an additional +5 boost.

**CR-05c** — GIVEN an Archer who has already advanced at level 10, WHEN any subsequent level-up occurs, THEN DEX does not receive an additional +20 boost and STR does not receive an additional +5 boost.

**CR-05d** — GIVEN a Mage who has already advanced at level 10, WHEN any subsequent level-up occurs, THEN INT does not receive an additional +20 boost and LUK does not receive an additional +10 boost.

**CR-06** — GIVEN a character with base STR = 10, flat_bonus = +5, and multiplier = 1.10, WHEN `compute_final_stat("STR")` is called, THEN the result equals (10 + 5) × 1.10 = 16.5.

**CR-07** — GIVEN a signal listener connected to `stat_changed`, WHEN `recompute_stats()` is called and N stats change value, THEN `stat_changed` fires exactly N times — once per stat whose old_value differs from its new_value — and fires zero times for stats whose value did not change.

**CR-08** — GIVEN an enemy entity is instantiated, WHEN its attribute schema is inspected, THEN it has STR, DEX, INT, and LUK fields of type `int`, each readable without error, each composing through the same `(base + flat) × multiplier` rule as a player character, and each emitting `stat_changed` on recompute.

**CR-09** — GIVEN a companion entity is instantiated, WHEN its attribute schema is inspected, THEN it has STR, DEX, INT, and LUK fields of type `int`, each readable without error, each composing through the same `(base + flat) × multiplier` rule as a player character, and each emitting `stat_changed` on recompute.

**CR-10** — GIVEN an enemy configured with no explicit STR value, WHEN its STR attribute is read, THEN the value is 0 (not null, not an error).

### Formulas

**FD-01** — GIVEN a Warrior with STR = 9, DEX = 4, weapon_att = 20, WHEN `compute_attack()` is called, THEN result = (9×4 + 4) × 20/100 = 8.0.

**FD-02** — GIVEN a Warrior with STR = 20, DEX = 10, weapon_att = 50, WHEN `compute_attack()` is called, THEN result = (20×4 + 10) × 50/100 = 45.0.

**FD-03** — GIVEN a Thief with DEX = 12, STR = 5, LUK = 8, weapon_att = 30, WHEN `compute_attack()` is called, THEN result = (12×4 + 5 + 8) × 30/100 = 18.3.

**FD-04** — GIVEN an Archer with DEX = 15, STR = 7, weapon_att = 40, WHEN `compute_attack()` is called, THEN result = (15×4 + 7) × 40/100 = 26.8.

**FD-05** — GIVEN a Mage with INT = 10, LUK = 5, weapon_att = 99, magic_att = 30, WHEN `compute_attack()` is called, THEN result = (10×4 + 5) × 30/100 = 13.5 and weapon_att is not used.

**FD-06** — GIVEN a Mage with INT = 20, LUK = 10, magic_att = 50, WHEN `compute_attack()` is called, THEN result = (20×4 + 10) × 50/100 = 45.0.

**FD-07** — GIVEN a character at level 1 with STR = 9, WHEN `compute_max_health()` is called, THEN result = 50 + (1×10) + (9×5) = 105.

**FD-08** — GIVEN a character at level 10 with STR = 20, WHEN `compute_max_health()` is called, THEN result = 50 + (10×10) + (20×5) = 250.

**FD-09** — GIVEN a character with STR = 14, armor_def_rating = 10, WHEN `compute_defense()` is called, THEN result = (14×0.5) + 10 = 17.0.

**FD-10** — GIVEN a character with defense = 17 and raw_damage = 30, WHEN `apply_damage(30)` is called, THEN damage_taken = max(1, 30−17) = 13.

**FD-11** — GIVEN a character at level 1 with DEX = 9, WHEN `compute_max_stamina()` is called, THEN result = round(50 + 1 + 4.5) = 56. (Round-to-nearest-integer, half-up. Matches Formula 7 definition.)

**FD-12** — GIVEN a character at level 5 with DEX = 20, WHEN `compute_max_stamina()` is called, THEN result = round(50 + 5 + 10) = 65.

**FD-13** — GIVEN a character with DEX = 100, WHEN `compute_stamina_regen()` is called, THEN result = 20 + (100×0.01) = 21.0.

**FD-14** — GIVEN a character with DEX = 4, WHEN `compute_stamina_regen()` is called, THEN result = 20 + (4×0.01) = 20.04.

**FD-15** — GIVEN a Warrior (class_base = 120) with DEX = 100, WHEN `compute_move_speed()` is called, THEN result = clamp(120 + 5.0, 120, 135) = 125.0.

**FD-16** — GIVEN a Warrior (class_base = 120) with DEX = 4 (minimum valid DEX), WHEN `compute_move_speed()` is called, THEN result = clamp(120 + 0.20, 120, 135) = 120.2. The class_base floor clamp is a defensive guard — it is never triggered by any valid positive DEX value and should not error if reached via edge construction.

**FD-17** — GIVEN a character with LUK = 40, WHEN `compute_crit_chance()` is called, THEN result = min(0.80, 0.02 + 0.10) = 0.12.

**FD-18** — GIVEN a character with INT = 100, WHEN `compute_magic_reduction()` is called, THEN result = min(0.75, 100×0.002) = 0.20.

**FD-19** — GIVEN a character with LUK = 50 and base_drop_rate = 0.10, WHEN `compute_effective_drop_rate(0.10)` is called, THEN drop_rate_bonus = 0.10, effective = 0.11.

**FD-20** — GIVEN a character with LUK = 200 and base_drop_rate = 0.50, WHEN `compute_effective_drop_rate(0.50)` is called, THEN drop_rate_bonus = 0.40, effective = 0.70.

### Edge Cases

**EC-01** — GIVEN any character with weapon_att = 0 (or magic_att = 0 for Mage), WHEN `compute_attack()` is called, THEN result = 0 (not negative, not an error).

**EC-02** — GIVEN a character with defense = 20 and raw_damage = 20, WHEN `apply_damage(20)` is called, THEN damage_taken = 1 (not 0).

**EC-03** — GIVEN a character with defense = 30 and raw_damage = 10, WHEN `apply_damage(10)` is called, THEN damage_taken = 1 (not 0 or negative).

**EC-04** — GIVEN a character with max_health = 200 and current_health = 180, WHEN a stat change causes max_health to recompute to 100, THEN current_health is immediately clamped to 100.

**EC-05** — GIVEN a character with max_health = 100 and current_health = 60, WHEN a stat change causes max_health to recompute to 150, THEN current_health remains at 60 (HP is not healed by stat increases).

**EC-06** — GIVEN a character with LUK = 400 (raw result = 1.02), WHEN `compute_crit_chance()` is called, THEN result = exactly 0.80.

**EC-07** — GIVEN a character with LUK = 312 (raw result = 0.80), WHEN `compute_crit_chance()` is called, THEN result = exactly 0.80 (cap is inclusive).

**EC-08** — GIVEN a character with INT = 500 (raw result = 1.00), WHEN `compute_magic_reduction()` is called, THEN result = exactly 0.75.

**EC-09** — GIVEN a character with INT = 375 (raw result = 0.75), WHEN `compute_magic_reduction()` is called, THEN result = exactly 0.75 (cap is inclusive).

**EC-10** — GIVEN a companion with max_stamina = 0, WHEN a stamina drain action is triggered, THEN current_stamina remains 0 and no error is raised.

**EC-11** — GIVEN a character with two separate +10% multiplier buffs on the same stat, WHEN `compute_final_stat()` is called, THEN the combined multiplier is 1.20 (not 1.21).

**EC-12** — GIVEN a Warrior (class_base = 120) with DEX = 10000, WHEN `compute_move_speed()` is called, THEN result = exactly 135.0.

**EC-13** — GIVEN a character with LUK = 0, WHEN `compute_crit_chance()` is called, THEN result = 0.02 (the base floor, not 0).

**EC-14** — GIVEN a character with INT = 0, WHEN `compute_magic_reduction()` is called, THEN result = 0.0.

**EC-15** — GIVEN a character with LUK = 400 and base_drop_rate = 0.90, WHEN `compute_effective_drop_rate(0.90)` is called, THEN raw_effective = 0.90 × (1 + 400×0.002) = 0.90 × 1.80 = 1.62, and result = exactly 1.0 (clamped per Formula 12).

**EC-16** — GIVEN a character with defense = 17 and magic_reduction = 0.20, WHEN an elemental physical strike deals 30 physical + 20 magic raw damage in a single hit, THEN physical_taken = max(1, 30−17) = 13, magic_taken = 20 × (1−0.20) = 16.0, total_taken = 29, and defense is not applied to the magic component nor is magic_reduction applied to the physical component.

**EC-17** — GIVEN an attack is registered with `compute_attack()` = 8.0 at the moment of hit registration, WHEN a STR buff is applied during the same frame before the hit damage is resolved, THEN the hit deals 8.0 damage (the pre-buff value), and `compute_attack()` reflects the new buffed value only after the frame boundary has passed.

**EC-18** — GIVEN a Warrior with `compute_attack()` = 8.0 and a forced critical roll (100% crit test override), WHEN the hit resolves, THEN damage_before_defense = 8.0 × 1.5 = 12.0.

**EC-19** — GIVEN a character with LUK = 0 and a confirmed non-critical roll, WHEN the hit resolves, THEN damage_before_defense equals `compute_attack()` exactly (no crit multiplier applied).

### Cross-System Integration

**INT-01** — GIVEN a Warrior at level 9 with STR = 9, weapon_att = 20 (attack = 8.0), WHEN job advancement applies +20 STR (final STR = 29), THEN `compute_attack()` = (29×4 + 4) × 20/100 = 24.0 immediately.

**INT-02** — GIVEN a Warrior with STR = 9, DEX = 4, weapon_att = 20 (attack = 8.0), WHEN the player spends 1 AP into STR (STR becomes 10), THEN `stat_changed` fires with stat_name = `"attack"`, old_value = 8.0, new_value = 8.8, and `compute_attack()` returns (10×4 + 4) × 20/100 = 8.8 without any explicit recompute call.

**INT-03** — GIVEN a character at level 1 with base STR = 4, flat_bonus +5 to STR, and STR multiplier 1.10, WHEN `compute_max_health()` is called, THEN it uses composed STR = (4+5)×1.10 = 9.9, not raw base STR = 4.

**INT-04** — GIVEN a character with STR = 14, armor_def_rating = 10 (defense = 17.0) receiving raw_damage = 30, WHEN damage is applied, THEN current_health decreases by exactly 13.

**INT-05** — GIVEN a signal listener connected to `stat_changed` on a level 9 Warrior, WHEN the character levels up to 10 and job advancement applies its STR boost, THEN `stat_changed` fires for `"STR"` and for each derived stat that depends on STR (at minimum: `"attack"`, `"max_health"`, `"defense"`), and signals are not suppressed during the batch update.

**INT-06** — GIVEN an enemy with STR = 15 and armor_def_rating = 5, WHEN `compute_defense()` is called on the enemy, THEN result = (15×0.5) + 5 = 12.5.

**INT-07** — GIVEN a companion with DEX = 10 at level 1 (max_stamina = 56) and current_stamina = 56, WHEN a stamina drain of 10 is applied, THEN current_stamina = 46 with no error.

## Open Questions

1. **Mage weapon property naming** — This GDD uses `magic_att` for Mage weapon attack rating and `weapon_att` for physical weapons. The Inventory & Equipment GDD must confirm these as two distinct item properties and specify whether a weapon can carry both (hybrid physical/magic weapon). Owner: Inventory & Equipment GDD. Resolve before authoring that GDD.

2. ~~**Stamina regen lockout timer**~~ — **RESOLVED**: Regen begins after a 1.0-second lockout delay following the last stamina-costing action. Defined as system constant `stamina_regen_lockout_delay = 1.0 s` in Formula 8. Runtime tick enforcement is owned by Stamina GDD.
