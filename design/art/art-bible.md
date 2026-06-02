# Art Bible: Ashen Maple

*Created: 2026-05-28*
*Status: In Progress — Sections 1, 4, 7 complete. Sections 2, 3, 5, 6, 8, 9 pending.*
*Visual Identity Anchor: Vibrant Dark Fantasy*

---

## 1. Visual Identity Statement

**Style anchor: Vibrant Dark Fantasy**

**One-line visual rule**: The world belongs to the dark; the hero and every threat are lit from within — saturated, readable, alive. When anything fights for visual attention with a character or attack, the environment yields.

### Supporting Principles

**Principle 1 — Saturation Hierarchy** *(pillar: Read the Rhythm)*

Enemies, players, and combat VFX occupy the top saturation tier. Environment art occupies a lower saturation band. Both can be richly painted — this is not a greyscale-vs-color distinction — but the environment's saturation ceiling is always below the character floor.

Design test: *If an enemy's wind-up animation is hard to distinguish from the background at a glance, the background's saturation is too high. Desaturate the background; never mute the animation.*

**Principle 2 — Warm Characters, Cold World** *(pillar: Fear Becomes Confidence)*

Character designs — player, companions, and humanoid enemies — carry warm undertones (amber, ochre, rose, gold). The world uses cool undertones (slate, ash, deep teal, shadow violet). This temperature split ensures characters feel present and vital inside environments that feel ancient and hostile. As the player gains confidence, warm light expands in the environment (campfires, companion lanterns, safe zones) — the world literally warms as fear recedes.

Design test: *If a new environment makes a character design feel "at home," the environment is too warm. The character should always feel like a warm thing moving through a cold world.*

**Principle 3 — Silhouette Legibility at Combat Distance** *(pillar: Motion Is the Answer)*

Every character and enemy must have an immediately readable silhouette at 50% viewport zoom (the approximate distance during active combat). Attacks, poses, and transitions must be distinguishable by shape alone, before color or detail registers. Detail exists to reward close inspection, not to communicate combat information.

Design test: *Screenshot a combat frame, convert to pure black silhouette, and reduce to 25% size. If you cannot identify the character, the enemy type, and the attack phase from silhouettes alone, the design needs shape revision before detail passes.*

### Distinctiveness vs. Comparators

- **Hollow Knight**: melancholy and smallness. Darkness is the point; characters are humble and monochromatic.
- **Blasphemous**: grotesque awe. Extreme desaturation, grimness as aesthetic. No warmth is intentional.
- **Dead Cells**: adrenaline. Neon-on-dark, too fast to feel warmth.

Ashen Maple's differentiator is **warmth inside danger**. Characters carry personality and presence — they are vital. The companion system reinforces this: warm character temperatures cluster together, creating a moving pocket of warmth inside a cold, hostile world. No comparator does this.

---

## 2. Mood & Atmosphere

[To be designed]

---

## 3. Shape Language

[To be designed]

---

## 4. Color System

*Authored: 2026-05-30. References: MapleStory (class color identity, high-saturation VFX), Hollow Knight (warm-character-against-cold-world principle, environment yields to character). Approved before Combat Feedback and HUD GDDs per AD-PHASE-GATE concern.*

### 4.0 Purpose

Color here is not decoration — it is communication. Every hue decision derives from the governing truth in Section 1: **the world belongs to the dark; the hero and every threat are lit from within.** A player who has never read this document should, within two hours of play, have internalized the color vocabulary through muscle memory alone. That is the success condition for this section.

---

### 4.1 Primary Palette — Seven Anchors

These seven colors are the load-bearing walls of the visual system. Every downstream decision — class VFX, semantic cues, UI, environment tints — is either a direct use of these anchors or a controlled deviation justified in writing.

**Anchor 1 — Ashen Slate** *(World Foundation / Environmental Default)*
A cool, mid-dark blue-grey: roughly 15–20% saturation, lower-mid value. The skin of the world — stone floors, cave ceilings, ambient fog, dusk sky. It exists to be pushed aside by characters and VFX. Design test: place a fully colored Warrior sprite against pure Ashen Slate. If the character does not immediately win visual attention, the slate is too bright or too warm.

**Anchor 2 — Deep Teal Void** *(Environmental Darkness / Deep Shadow)*
Saturated-but-dark teal — hue in the blue-green range, ~40–50% saturation, very low value. Background parallax architecture, open sky in dangerous areas, cave interiors before a light source fires. Pure black shadow feels dead in 2D; Deep Teal Void keeps shadows alive and cold.

**Anchor 3 — Ember Gold** *(Player Warmth / Hope / Safe Zone Signal)*
Warm, slightly orange-shifted gold — high value, high saturation. The color of firelight, checkpoint lanterns, companion presence, and the player character's rim light. When it appears, the player should feel at a primal level: *I am not alone. Something warm is here.* This is the most emotionally loaded color in the game.

**Anchor 4 — Crimson Signal** *(Danger / Enemy Intent / Incoming Threat)*
Saturated red with a slight orange lean — high chroma, mid-to-high value. An alarm color — never decorative. Every appearance of Crimson Signal in a play context means: *something is about to hurt you.* The orange lean differentiates it from decorative blood-reds; this color is active, not atmospheric.

**Anchor 5 — Void Violet** *(Boss Presence / World Corruption — EXCLUSIVE to enemies and world threats)*
Deep, saturated purple-violet — high saturation, mid-low value. The color of boss arenas, corrupted enemy variants, and environmental wounds in the world. **No player-aligned entity (player character, companion, or class VFX) uses this color.** It belongs entirely to the world's threat layer. When a player sees Void Violet in the environment, they know something dangerous lives here.

**Anchor 6 — Celadon Recovery** *(Healing / Safety / Friendly Action)*
Cool, slightly desaturated green-teal — ~40–50% saturation, mid value. Sits at the teal-green boundary; distinct from both Deep Teal Void (too dark, too blue) and pure greens (too naturalistic). Calm, reliable, and unambiguously positive. Never appears on enemies or in danger contexts.

**Anchor 7 — Pale Ivory** *(UI Foundation / Character Highlight / Universal Legibility)*
Warm near-white with the smallest push toward Ember Gold — essentially white with a breath of warmth. Outlines characters against any background, forms the base of UI text, and defines skill icon borders. Never used in world environments — its exclusivity to characters and UI gives it signal value.

---

### 4.2 Semantic Color Vocabulary

Every VFX artist, UI designer, and animator must know these assignments. Deviation requires Art Direction sign-off.

**Danger / Incoming Attack — Crimson Signal**
Full-sprite overlay or localized limb/weapon highlight before any telegraphed attack. Area-attack warning zones are outlined in Crimson Signal with a pulsing (not static) interior. The pulse is mandatory — it provides motion-based differentiation for colorblind players.

**Parry Success — Pale Ivory → Ember Gold flash (0.15s)**
Successful parry fires a radial burst: Pale Ivory resolving into Ember Gold over 0.15 seconds, with a 2–3 frame contact freeze. Reads as warmth winning against cold threat. Backup cues: metallic ring audio + camera micro-shake.

**Stagger Building — Amber-Orange** *(between Crimson Signal and Ember Gold, more orange, mid-saturation)*
As stagger accumulates, an enemy's outline or weak point pulses with slow amber-orange that increases in frequency as the threshold approaches. Means: "this is working — keep going." Warm enough to feel player-favorable; not yet Ember Gold (that's the payoff). Backup cue: stagger bar fill animation + enemy idle-interrupt animation.

**Stagger Break — Ember Gold burst + Void Violet secondary ring (0.3s)**
Two-tone radial burst: Ember Gold inner ring (player's victory) surrounded by a quick Void Violet dissipation ring (the enemy's resistance collapsing). The only context where Void Violet reads as a positive outcome for the player. Nothing else in the vocabulary uses a two-ring burst — stagger break is unmistakable. Backup cues: bone-crack audio + enemy posture animation.

**Burst Window — Ember Gold rapid pulse (3–4Hz)**
When an enemy enters their burst window (optimal DPS window), their outline runs Ember Gold at urgency frequency. Distinct from stagger-build amber (different hue, different location, different frequency). Players learn the frequency = urgency relationship within 15 minutes. Backup cue: urgency chime audio + enemy exposed-state animation.

**Healing / Recovery — Celadon Recovery**
All healing fires Celadon particles with upward-floating direction (opposite of outward/downward damage scatter). Backup cues: soft chime audio + upward-arc particle motion.

**Companion Presence — Ember Gold (reduced intensity)**
Companions share the Ember Gold warmth family but at ~75% saturation and value — warm but subordinate to the player. In a world of cold threats, every warm light is a potential ally. Incapacitated companions shift to pale grey (warmth withdrawn = needs rescue). Backup cue: companion idle animation + distinct companion silhouette.

**Enemy Presence — No single unifying color (enemies wear the world's cool palette)**
Enemies carry the world's cool undertones — they ARE the world's danger made mobile. Their threat communicates through Crimson Signal on attack (not on passive presence). Corrupted variants add a Void Violet secondary layer. Backup cue: silhouette shape differentiation + audio aggro indicator.

**Safe Zone / Checkpoint — Ember Gold (static, non-pulsing)**
Safe-zone gold is STATIC. Pulsing gold = combat urgency. Static gold = rest. Checkpoint lanterns, campfires, and safe-zone ambient light all use non-pulsing Ember Gold. As the player gains mastery and safe zones proliferate, the world literally gains more static gold — the "Fear Becomes Confidence" pillar expressed as ambient light. Backup cue: hearth audio + NPC/campfire prop.

---

### 4.3 Class Color Identities

**The class color IS the class** (MapleStory principle). A player should identify an unknown character's class from skill VFX color alone, across the room. These four colors are never reused in other semantic contexts and never applied to enemy designs without explicit corrupted-variant signaling.

**Warrior — Molten Iron Red**
Deep red with a brown-iron undertone — high saturation, mid value. Darker and heavier than Crimson Signal (the danger color, which must stay exclusive). Warrior red carries the weight of iron and force, not alarm. VFX signature: iron-ember particle trails, deep red shockwaves, orange-core impact flashes. Conflict to avoid: Warrior red must never drift toward Crimson Signal's brighter, more orange-pure hue. If placed side-by-side (e.g. in a tutorial), they must be immediately distinguishable — Warrior is darker and warmer.

**Thief — Cold Amber / Shadow Gold**
Amber-gold primary with a shadow-black secondary — mid saturation, value shifts bright to near-black. Thieves live between light and shadow. The amber connects them to the player warmth family (fast, not malevolent); the shadow-black secondary makes every skill feel like a glimpse of something — bright, then gone. VFX signature: sharp amber slashes with black shadow afterimages, void-dark silhouette pops on blink/dash skills.

**Archer — Forest Jade**
Deep, saturated cool green — more jade than lime, more shadow-canopy than grass. Cool enough to coexist with the world's teal-slate palette without vanishing into it; distinct from Celadon Recovery (lighter, more blue-shifted — healing, not class identity). VFX signature: deep jade arrow trails, cool green wind distortion, leaf-fragments decaying to ash grey. Production rule: Forest Jade must sit at 60%+ saturation; environmental greens max at 30% saturation. Design test: Archer combat frame in Blighted Canopy — class VFX must separate from environmental glow in greyscale at 25% size.

**Mage — Deep Indigo**
Night-sky blue-violet — sits between blue and violet on the hue wheel but reads as its own distinct hue. More blue than Void Violet (which leans red-purple), clearly distinct from the environment's cool teal-blue. Deep Indigo is exclusively player-aligned (unlike Void Violet); it is the color of knowledge and mastery, not of corruption. VFX signature: orbiting/curving particle systems, arcane sigil glow at mid-indigo, bright indigo-white core on high-power spells (barely-controlled energy), geometric pattern overlays. Conflict management: Deep Indigo vs. Void Violet must be distinguishable — Indigo is more blue-shifted and appears on a player character (point source, controlled motion); Void Violet is more red-shifted and appears as environmental aura (area, slow pulse). Shape and motion carry the disambiguation alongside hue.

---

### 4.4 Per-Area Color Temperature Rules

**Governing rule: The "cold world" principle applies universally as a baseline.** No area is warm by default — warmth is earned and placed, never ambient. What varies between regions is the hue family within the cool range and the value range (how dark is dark), not temperature.

**Hub World — The Ashen Keep**
Hue: Cool Grey-Slate (Anchor 1 dominant). Value: Wide. Character: The palette baseline; where Ember Gold static light sources are densest. Returning to the Keep should feel like returning to warmth. As the player ventures into regions, safe-zone gold becomes rarer — the Keep's warmth is the emotional anchor.

**Region 1 — The Sunken Tombs**
Hue: Deep Teal-Blue (Anchor 2 dominant). Value: Narrow and dark — maximum shadow depth. Character: Near-monochrome underground. Characters and VFX pop most here. Companion presence reads as the only other warmth — this is where Pillar 3 is felt most visually.

**Region 2 — The Blighted Canopy**
Hue: Forest Green-Teal (Anchor 2 shifted toward green family). Value: Mid — filtered, sickly ambient. Character: Corrupted forest. Void Violet appears as environmental corruption detail (warning, not dominant). Archer VFX (Forest Jade, 60%+ saturation) must separate clearly from environmental green (max 30% saturation). Production rule: Caustic environmental greens must not overlap Archer VFX in saturation.

**Region 3 — The Ashfall Wastes**
Hue: Cool Warm-Grey (Anchor 1 with ash-brown secondary — closest to "warm" the world gets outside safe zones). Value: Wide, high contrast — pale ash ground against near-black sky. Character: Dynamic rim-light logic required — characters against pale ground need dark outline definition; characters against dark sky need Ember Gold/Ivory rim light.

**Region 4 — The Drowned Spires**
Hue: Deep Blue-Teal / Subaquatic (Anchor 2 toward pure blue). Value: Mid-dark with animated cool-blue caustic light. Character: Caustic patterns max 25% saturation; animations must pause or suppress over enemy telegraph zones — environment motion cannot compete with Crimson Signal.

**Region 5 — The Calcified Peaks**
Hue: Ice Blue / Near-White Cool (Anchor 1 shifted toward white, high value). Value: Wide, bright-end weighted — brightest-ambient region. Character: Characters must read against lighter background; rely on saturation separation, not value separation. Calcified Peaks silhouette test requires greyscale AND hue removal — if characters don't read without color, they need darker midtones, not brighter highlights.

**Boss Arenas**
All boss arenas apply a Void Violet atmospheric overlay (fog, vignette, ground tint) on top of the region's base palette. Environment background layers globally desaturated by 25% during the fight — maximum VFX and boss silhouette legibility. When the boss dies, Ember Gold light floods back in. The warmth reclaims the space.

---

### 4.5 UI Palette — Closed System

UI color is separate from world color. World colors do not bleed into UI; UI colors do not appear in the world (except explicitly designed overlaps like checkpoint interaction prompts). UI must remain legible against all regional backgrounds and high-VFX boss fights.

| UI Element | Color | Notes |
|---|---|---|
| Panel background | Near-black, faint Ember Gold trace (<5% warmth) | Separates from world shadows subconsciously |
| Primary text | Pale Ivory | All item names, dialogue, system messages |
| Secondary text / inactive | Cool mid-grey | Greyed options, inactive menu items |
| Player HP bar (active) | Celadon Recovery fill | Reinforces health = healing color |
| Player HP bar (lost HP ghost) | Dark red-brown static fill | Not Crimson Signal — static, not pulsing |
| Enemy HP bar | Crimson Signal gradient (brighter as HP drops) | Threat-red; urgency builds as enemy nears death |
| Stamina bar | Cool Amber / Pale Orange | Warms to Crimson pulse below 20% |
| Stagger bar (enemy) | Amber-orange fill → Ember Gold near break | Mirrors in-world semantic colors |
| Companion status | Ember Gold (healthy) → Amber (injured) → Pale Grey (incapacitated) | Warmth withdrawal = rescue signal |
| Interactive prompt | Ember Gold icon + Pale Ivory text + near-black panel | Three-element pattern = "I can interact here" |
| Map — player dot | Ember Gold | |
| Map — companion dot | Softer Ember Gold (75% value) | |
| Map — enemy dot | Crimson Signal | |
| Map — checkpoint icon | Static Ember Gold lantern | |
| Map — unexplored | Ashen Slate fill | |

---

### 4.6 Colorblind Safety — Production Requirements

All semantic colors must pass three mandatory checks before any milestone review:
1. **Shape differentiation** — different semantic states use visually distinct VFX shapes
2. **Motion differentiation** — different semantic states use visually distinct animation patterns
3. **Audio differentiation** — different semantic states have distinct audio signatures

Color is the first-channel cue, not the only cue. If removing color destroys the communication, the design is incomplete.

**Risk Pair 1 — Crimson Signal vs. Celadon Recovery** *(Red-Green, Deuteranopia / Protanopia — HIGH)*
Most common colorblindness; affects ~8% of males. These are the two most critical combat colors.
Backup cues required: Danger = 4–6Hz pulse + incoming-attack audio sting + directional indicator. Healing = upward-floating particle direction + soft chime audio. UI differentiation: player HP bar = bottom-left + heart icon; enemy HP bar = top-center + threat icon.
**Validation:** Run all combat VFX through deuteranopia simulation (Color Oracle / Coblis) before every milestone review.

**Risk Pair 2 — Crimson Signal vs. Ember Gold** *(Red-Yellow confusion, Tritanopia — MEDIUM)*
Backup cues required: Parry success = radial burst shape + metallic ring audio + freeze frame (shape and audio carry the meaning). Danger = pulsing frequency + directional source on attacking enemy + danger sting audio.

**Risk Pair 3 — Forest Jade (Archer) vs. Celadon Recovery (Healing)** *(Green-range, Protanopia — MEDIUM)*
In Archer combat, class VFX must not read as healing.
Backup cues required: Archer VFX = angular, fast, directional particles. Healing = soft, upward-floating, character-centered spherical particles. Shape language carries full disambiguation.

**Risk Pair 4 — Deep Indigo (Mage) vs. Void Violet (Boss/Corruption)** *(Blue-purple distinction, Tritanopia — LOW-MEDIUM)*
Both are blue-violet family; context separates them (character VFX vs. environmental aura).
Backup cues required: Mage VFX = orbiting/curving motion, point-source origin, character-attached. Boss Void Violet = area aura, slow environmental pulse, fills arena space. Motion type and source location carry disambiguation.

---

## 5. Character Design Direction

[To be designed]

---

## 6. Environment Design Language

[To be designed]

---

## 7. UI / HUD Visual Direction

*Authored: 2026-05-30. Art Director draft + UX Designer alignment review. Blocking conflicts resolved before writing: (1) stamina bar is always visible, never fades — UX requirement; (2) burst window entry is instant-flash sub-60ms, no bounce — timing-window preservation. Phase-segment markers added as boss bar first-class constraint per UX review. Stagger rate-of-accumulation visual language specified.*

### 7.1 Diegetic vs. Screen-Space Philosophy

Ashen Maple uses a **predominantly screen-space HUD with disciplined minimalism.** The rationale: the 2D side-scrolling perspective and fast combat cadence make true diegesis impractical — world-space floating indicators create z-sorting noise and fight for visual hierarchy against character VFX. The correct reference is Hollow Knight: UI lives apart from the world but respects it by staying silent unless it has something to say.

**The governing rule: a HUD element earns screen space only when it is actively informing a decision.** Elements that are not decision-relevant are invisible or reduced to passive ambient state — with one exception: stamina is permanently visible (see 7.2).

Two narrow hybrid exceptions are permitted:
- **Stagger accumulation particle drift**: A brief particle trail rising from a staggered enemy toward the stagger bar acknowledges cause-and-effect in world space before resolving on-screen. This is a VFX bridge, not a diegetic element.
- **Interactive prompts**: Float in world space 64px above the interactable's top bounding box, tethered to a screen-space anchor to prevent off-camera clipping. The only true hybrid element.

---

### 7.2 HUD Element Layout

All coordinates assume **1920×1080 reference resolution**, anchor-relative. Elements scale proportionally (see 7.6 for scale rules).

**Permanently visible — always on-screen regardless of game state:**

| Element | Position | Rationale |
|---|---|---|
| Player HP bar | Top-left, 32px from top, 40px from left | Players must know their HP at all times |
| **Stamina bar** | Top-left, directly below HP bar, 6px gap | **Always visible — cannot fade. Player needs stamina state before committing to a dodge input, not after.** In exploration: 50% opacity. In combat: 100% opacity. |

**Passive ambient (visible in exploration, low-emphasis):**

| Element | Position | Passive state |
|---|---|---|
| Companion status row | Below stamina bar, 8px gap | Ember Gold icons at 50% opacity; warmth-withdrawal pulse begins if any companion drops below 40% HP |

**Combat-active (fades in at 120ms ease-out on first hostile aggro; fades out 4 seconds after combat ends):**

| Element | Position | Notes |
|---|---|---|
| Player HP bar | Same anchor — expands to full opacity | 120ms transition |
| Enemy HP bar | Top-center, 48px from top | Primary targeted enemy only |
| Enemy stagger bar | Directly below enemy HP bar, 4px gap | Always shown in combat; see 7.5 for rate-of-accumulation animation |
| Active buff/debuff icons | Top-right, 32px from top, 32px from right | Left-to-right flow, wraps down; max 12 icons before scroll indicator |
| Skill hotbar | Bottom-center, 24px above bottom | 50% opacity in exploration; 100% in combat |
| Damage numbers | World-anchored, float upward from hit point | See 7.5 |

**Burst window indicator:**
Centered horizontally, 28% from top. Not a fixed slot — appears at neutral focal depth between player position and the enemy bar. Instant-flash entry (sub-60ms, no animation, no bounce). See 7.5 for active-state behavior.

**Boss encounter only (replaces standard enemy HP bar):**

| Element | Position | Notes |
|---|---|---|
| Boss HP bar | Bottom of screen, 80px from bottom, full-width minus 120px horizontal margins | Phase-segmented (see 7.2a) |
| Boss stagger bar | 4px above boss HP bar | Same rate-of-accumulation treatment as standard stagger bar |
| Boss name | Above boss HP bar, SemiBold 28px all-caps | Appears on combat entry, 300ms fade-in |

**Interactive prompts:**
World-space, 64px above interactable top bounding box. Three-part composition: Ember Gold icon (24×24px) + Pale Ivory label text + near-black pill background. If equidistant between two interactables, only the nearest shows.

**Companion status row (expanded):**
Each of up to 4 companions occupies a 48×48px slot. Contents: 32×32px portrait thumbnail, HP ring using the Section 4 warmth-withdrawal ramp (Ember Gold → Amber → Pale Grey), role icon (healer/tank/damage/utility) at bottom-right corner. Incapacitated state: portrait desaturates fully and the slot border flashes once with a hard-cut (not a fade) before holding the desaturated state — the hard-cut ensures peripheral detection in combat.

---

### 7.2a Boss Health Bar — Phase-Segment Structure

Boss bars are **phase-segmented as a first-class design constraint**, not a post-hoc addition. The segment structure must be authored before any boss health bar visual development begins.

**Segment design rules:**
- Each phase threshold is marked by a notch in the bar dividing it into segments. Notch width: 3px, color: near-black (the panel background color), creating a hard visual break.
- The current phase segment fills and drains within its segment only — on phase transition, the current segment shatters (a short burst animation distinct from normal HP loss) and the bar advances to the next segment.
- Phase count drives the bar's visual complexity, not the reverse. A two-phase boss has two segments; a four-phase boss has four. Segments are not equal-width — they are proportional to each phase's HP allocation.
- Phase break animation: the draining segment flashes Pale Ivory, then contracts to the notch with a 150ms ease-in. The new active segment fades in from 0 opacity at 120ms. The entire transition takes under 300ms.
- Boss bars never use a single undivided fill. An undivided boss bar is a design error.

---

### 7.3 Typography Direction

**Font personality:** Condensed, slightly angular serif with restrained calligraphic influence. Letterforms carry the weight of old-world inscription rendered precise — engraved stone, not distressed. Avoid rounded terminals; the world is dangerous, not soft.

| Use | Weight | Size at 1080p | Notes |
|---|---|---|---|
| Boss name | Bold / Black | 28px | All-caps, letter-spacing +0.08em |
| Skill / buff names (hover/focus) | SemiBold | 18px | Mixed case |
| Tooltip body | Regular | 16px | Minimum readable size at 80cm/24in |
| Damage numbers — standard | Bold | 22px | |
| Damage numbers — critical | Black/ExtraBold | 30px | Scale-up animation; see 7.5 |
| Damage numbers — healing | Regular Italic | 20px | |
| HP / stamina numeric readout | Medium Tabular | 14px | Tabular figures only — numbers must not shift column width on value change |
| Interactive prompt label | Regular | 16px | |

**Legibility floor:** No UI text below 14px at 1080p. At 4K: ×2. At 720p: ×0.85 (not ×0.75 — legibility floor takes priority over geometric proportion).

**Color application:** Standard text: Pale Ivory on near-black panels. Damage numbers inherit semantic color from damage type (Section 4). Negative-state text (debuffs, critical HP warnings): Crimson Signal — urgency carried by color, not weight escalation.

---

### 7.4 Iconography Style

**Style: Outlined symbolic with single-color fill.**

Every icon must read at 24×24px. Design language:
- 2px stroke weight at 48×48 master size (scales to 1px at 24px render)
- Stroke: Pale Ivory at full opacity
- Fill: single flat color from the Section 4 closed UI palette, 70% opacity — no gradients, no drop shadows
- Corners: 1px rounded inner corners only; outer corners remain hard
- No literal illustration inside icons — symbolic glyphs only. Prevents competition with VFX and ensures small-size legibility.

| Icon category | Fill color |
|---|---|
| Skill / active ability | Class accent color (Section 5) |
| Buff (positive) | Celadon Recovery |
| Debuff (negative) | Crimson Signal |
| Companion: healer | Ember Gold |
| Companion: tank / damage / utility | Cool Amber / Crimson Signal / Pale Grey |
| Interactive prompt | Ember Gold |

**Buff/debuff layout:** 32×32px in top-right cluster. Hover/focus reveals tooltip below: name, duration as circular drain ring on icon border, one-line effect. The drain ring is the only animated element on an unfocused icon.

**Skill hotbar:** 6 slots, horizontal, 56×56px with 4px gaps. Active slot: 2px Ember Gold border. Cooldown: clockwise-draining dark overlay (not numeric). Countdown number appears only on the active slot when cooldown ≤5 seconds.

**Peripheral legibility requirement:** Ready vs. on-cooldown states must be distinguishable at peripheral distance, not only when the player looks directly at the bar. The overlay contrast between ready (no overlay) and on-cooldown (dark fill over icon) must exceed 40% value difference at the icon center.

---

### 7.5 HUD Animation Philosophy

**Rule: Animation communicates state change, not decoration.** Every animated behavior corresponds to a discrete game event. Nothing pulses, breathes, or loops without a cause.

**Player HP bar:**
- Damage: bar drains instantly to new value; ghost bar (30% opacity Pale Ivory) holds the pre-damage position for 600ms then drains to meet the live bar over 200ms. Ghost = "how much just happened."
- Healing: fills from current to new value over 400ms with a leading-edge Celadon Recovery glow.
- Critical HP (<20%): slow Crimson Signal pulse bleeds into the bar's background panel (not a screen-edge vignette — that impairs spatial awareness). Period: 2.4 seconds. Ambient, peripheral-detectable.

**Stamina bar:**
- Drain: real-time, no trail — precision resource, player needs accurate feedback.
- Recovery: fills left-to-right with a 60ms ease-in ramp at the leading edge.
- Full depletion: bar flashes once (200ms Crimson Signal pulse) before recovery begins.
- Overexertion window: bar turns Crimson Signal for the penalty duration, then recovers normally.

**Stagger bar — including rate-of-accumulation visual language:**
- Fill on hit: snaps to new value in one frame (no easing — communicates precise, impactful feedback per hit).
- **Leading-edge particle shimmer:** A short amber-orange particle trail on the fill's leading edge. The shimmer **accelerates in frequency and brightness when stagger is actively accumulating** (each hit refreshes it) and **dims and decelerates when no hits have landed for >0.5 seconds** (stalling signal). This gives the player a rate read, not just a current-value read.
- At 75% full: slow amber-orange pulse begins along the filled portion (1.8-second period).
- At 100% (stagger break): entire bar flashes Ember Gold for 300ms; bar clears and replaces with a downward-draining stagger-duration bar at constant linear rate.
- Stagger window expires: bar fades out over 150ms; accumulation bar fades back in at 0%.

**Burst window indicator:**
- **Entry: instant flash (sub-60ms). No scale animation. No bounce.** The indicator fires at full presence immediately — the DPS window begins the moment stagger breaks, and zero animation frames are sacrificed to an entrance effect.
- Active state: 1.2-second warm Ember Gold glow pulse while window is open.
- Exit (window consumed or expired): 120ms ease-in fade to invisible.

**Damage numbers:**
- Standard: float upward 48px over 600ms (ease-out), hold 200ms, fade 200ms. Bias upward and away from enemy torso/head to avoid telegraph silhouette occlusion.
- Critical: snap scale from 60% to 100% over 80ms (sharp), then standard drift. 2px camera impulse (not on the number itself — on the camera layer; coordinate with gameplay camera system).
- Healing: same drift, slower ease-out (900ms), slightly left of hit point to separate from simultaneous damage numbers.
- Stacking: 3+ numbers within 120ms collapse into a single combined number with Critical visual treatment.
- **Transparency rule:** Any damage number that overlaps the enemy bounding box must render at maximum 80% opacity — telegraph silhouette readability takes priority over number legibility. This is a rendering constraint, not an optional quality setting.

**HUD element transitions:**
- Fade in: 120ms linear
- Fade out: 200ms linear (exit always slower than entry — information lingers)
- Combat-state HP bar width expansion: 120ms ease-out. Position anchor never moves; only width changes.

---

### 7.6 Scale-Up and Accessibility Defaults

**Baseline:** 100% = all measurements in 7.2 and 7.3 at 1080p, calibrated for 80cm/24in desk viewing.

**Default shipped scale: 115%.** The game ships at 115% — not 100%. Players at living-room gamepad distances (150–200cm, 40in+ display) need larger UI. Shipping at 115% eliminates the most common accessibility complaint without requiring a settings dive.

**Scale range:** 70%–175% in 5% increments. Minimum 70% enforces the 14px legibility floor; maximum 175% serves low-vision players and large-display close-viewing.

**High-contrast mode (off by default, user-enabled):**
- Bar backgrounds → pure black (#000000)
- HP bars → #00E676 (active) / #FF1744 (enemy) — WCAG AA compliant against black
- Pale Ivory text: unchanged
- Icon strokes: 2px → 3px at master size
- Damage numbers: +1px hard black text shadow (0px blur)
- Color semantics remain identical — only the accessibility values of colors change.

**Text scale (independent of HUD scale):** 100%–150%, separate control. Players who need larger text but prefer compact layout can adjust without scaling everything.

**Motion reduction (off by default, user-enabled):**
- All animation durations capped at 80ms
- Burst window: fade only (no scale, no pulse)
- Damage numbers: appear and fade in place (no drift)
- HP ghost bar: suppressed; bar drains directly
- Critical HP pulse: replaced with static Crimson Signal tint (no pulsing)
- Functional feedback (bar drains, stagger clears, buff application) is unaffected — only aesthetic motion is reduced.

---

*Implementation note for UI programmer: All HUD scale, text scale, high-contrast, and motion-reduction values must be exposed as exported variables on the root HUD CanvasLayer node, driven by a single `UISettings` resource persisted to user save data. No HUD element hardcodes pixel sizes — all sizes multiply baseline values from this document against the settings resource. These baseline values are the source of truth.*

---

## 8. Asset Standards

[To be designed]

---

## 9. Reference Direction

[To be designed]
