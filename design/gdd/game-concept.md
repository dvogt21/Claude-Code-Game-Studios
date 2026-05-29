# Game Concept: Ashen Maple

*Created: 2026-05-28*
*Status: Draft*

---

## Elevator Pitch

> A 2D side-scrolling action RPG where you master precise Soulslike combat — parrying, dodging,
> and breaking enemies' will — as a warrior exploring a beautiful, dangerous world alongside
> companions who make the impossible barely possible.
>
> Like Hollow Knight, AND ALSO it has MapleStory's fluid class progression and high-risk gear
> enhancement — with a companion AI that creates genuine moments of mutual rescue.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 2D Action RPG / Soulslike |
| **Platform** | PC (Windows, Steam / Epic) |
| **Target Audience** | Mid-core to hardcore action RPG players, 18–35 |
| **Player Count** | Single-player (with AI-controlled party companions) |
| **Session Length** | 30–120 minutes |
| **Monetization** | Premium (TBD — companion gacha discussed but not finalized) |
| **Estimated Scope** | Large (36–60 months, solo dev) |
| **Comparable Titles** | Hollow Knight, Dead Cells, Blasphemous |

---

## Core Fantasy

You are a precise, dangerous fighter who reads the world's rhythm and punishes every mistake —
not through raw power, but through pattern mastery. You grow from terrified to confident,
and the companion beside you makes the final boss feel possible.

What Ashen Maple offers that nothing else does: the speed and class identity of MapleStory
fused with the tactical depth and emotional weight of a Soulslike, in a world that rewards
patience, composure, and knowing when to strike.

---

## Unique Hook

It's like Hollow Knight, AND ALSO it has MapleStory's fast side-scrolling mobility, job
advancement system, and gear enhancement — with a companion AI that creates genuine,
unscripted moments of mutual rescue.

The hook is behavioral: players will learn to treat combat as a rhythm game. The moment
that mental model clicks — the Sekiro realization — is what this game is designed to deliver.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Challenge** (mastery) | 1 | Telegraphed enemy patterns, parry timing, stagger system, fear-to-confidence arc |
| **Fellowship** (connection) | 2 | AI companions who create unscripted mutual rescue moments |
| **Discovery** (exploration) | 3 | New regions with distinct atmosphere, secrets, NPC recruitment |
| **Sensation** (sensory pleasure) | 4 | Parry sound feedback as dopamine, stagger break VFX, MapleStory-inspired music |
| **Fantasy** (identity) | 5 | Class advancement — Beginner → Warrior/Mage/Thief/Archer → specializations |
| **Expression** (creativity) | 6 | Build diversity, gear enhancement choices, companion composition |
| **Narrative** (story) | 7 | World lore, NPC companion arcs (TBD) |
| **Submission** (relaxation) | N/A | This is not a relaxing game |

### Key Dynamics (Emergent player behaviors)

- Players will treat bosses as rhythm puzzles — replaying encounters to "hear the music" rather than just react
- Players will form genuine emotional attachment to companions after a critical rescue moment
- Players will agonize over gear enhancement decisions — scroll or not? What if I fail?
- Players will naturally reposition during every engagement, developing spatial awareness as muscle memory
- Players will share memorable "I finally got it" moments with the community

### Core Mechanics (Systems we build)

1. **Real-time stamina combat** — roll dodge with I-frames, shield parry with a tight timing window, and single attacks that encourage repositioning over combo chains
2. **Visible stagger system** — enemies have a stagger bar that fills with attacks and parries; stagger break triggers a burst damage window that is the emotional climax of every fight
3. **Class progression** — Beginner → Warrior / Thief / Archer / Mage → advanced specializations (MapleStory-inspired job advancement)
4. **AI companion party** — up to 4 NPC companions with distinct roles (Tank, Healer, Support, DPS); companions act independently and can create unscripted rescue moments
5. **High-risk gear enhancement** — weapon and armor upgrade system with probability mechanics; enhancement can fail, creating genuine tension at every upgrade attempt

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Competence** (mastery, skill growth) | Pattern recognition, parry mastery, stagger management all grow visibly with play. Players feel the improvement. | Core |
| **Autonomy** (meaningful choice) | Class path, gear enhancement direction, companion composition, positioning — every decision matters. | Supporting |
| **Relatedness** (connection) | AI companions create genuine bonds through shared peril and mutual rescue, not scripted cutscenes. | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — boss kills, gear upgrades, class advancement milestones, pattern mastery goals. Primary audience.
- [x] **Explorers** — new regions with distinct atmosphere, hidden areas, NPC lore, gear secrets. Strong secondary appeal.
- [ ] **Socializers** — AI companions only; no multiplayer in MVP.
- [ ] **Killers/Competitors** — no PvP; competition is against the game's own difficulty.

### Flow State Design

- **Onboarding curve**: Castle Training Hall teaches combat fundamentals through failure — the Armored Knight telegraphs clearly enough that dying teaches you something every time. No tutorial text walls.
- **Difficulty scaling**: New enemies introduce new patterns; bosses require synthesizing everything learned so far. Difficulty escalates with the player's demonstrated competence.
- **Feedback clarity**: Stagger bar is always visible. Parry success has a distinctive audio cue ("each parry sound is dopamine"). Burst windows have clear visual VFX. The player always knows what just happened.
- **Recovery from failure**: Respawn at checkpoint with full HP; enemies reset. Death is a teacher, not a punishment — the question is always "what can I learn from that?"

---

## Core Loop

### Moment-to-Moment (30 seconds)

Move → Read enemy telegraph → Dodge (I-frame roll) OR parry (shield, tight window) → Land punish attack → Stagger builds → Stagger breaks → Burst damage window opens → Enemy recovers → Repeat.

*The emotional core: maintaining rhythm and composure while hunting for pattern openings. Every fight is a conversation.*

### Short-Term (5–15 minutes)

Clear a room or encounter group → Recover stamina → Face the next room, mini-boss, or elite encounter → Earn resources, gear drops → Progress deeper into the dungeon.

*"One more room" hook: the next room might have better loot, or a weak enemy worth farming, or a companion recruitment opportunity.*

### Session-Level (30–120 minutes)

Enter a dungeon → Work through encounters → Challenge the dungeon boss → Earn significant gear rewards → Return to hub → Upgrade equipment (feel the scroll tension) → Plan next run.

*Natural stopping point: after a boss kill or a significant gear upgrade. Reason to return: the next dungeon is now unlocked, or an enhancement roll went perfectly and you want to test it.*

### Long-Term Progression

Level up → Unlock base class → Complete job advancement quest → Master class skills → Earn and enhance gear (elemental infusions, enhancement scrolls) → Explore new region → Recruit companion → Face harder content → Specialize into advanced class.

### Retention Hooks

- **Curiosity**: New region locked behind current boss; companion recruitment quest discovered mid-dungeon; what does the chaos scroll do to this helmet?
- **Investment**: Class advancement progress, companion bonds built through shared battles, carefully enhanced gear
- **Mastery**: That boss you almost had — next session you'll read the second phase differently
- **Sensation**: The parry sound, the stagger break, the burst window — they never get old

---

## Game Pillars

### Pillar 1: Read the Rhythm

Combat is music, not reflexes. Every dangerous enemy has a pattern that players can learn. Mastery means hearing the beat underneath the chaos — not reacting faster, but understanding deeper.

*Design test: "If we're debating a random vs. telegraphed attack, this pillar says always telegraph. The player should always be able to learn this."*

### Pillar 2: Fear Becomes Confidence

The game begins terrifying and ends triumphant. The arc from scared to capable IS the emotional journey. Death always teaches something — it is never arbitrary. A player who dies should always be able to answer "what do I do differently next time?"

*Design test: "If a mechanic punishes death harshly, ask: does the player learn something here? If not, redesign the encounter — not just the penalty."*

### Pillar 3: No One Fights Alone

Companions create unrepeatable moments of mutual rescue. The best memories happen when they saved you, or you saved them, and neither could have done it alone. Companions are not stat bonuses — they are emotional anchors.

*Design test: "Does this companion feature create a moment I will remember? If it's just a passive stat buff with no emergent behavior, it doesn't belong."*

### Pillar 4: Motion Is the Answer

Standing still is death. Positioning, dodging, and constant repositioning are how players survive — not endurance, not tanking. The player who moves well lives; the player who plants and spams does not.

*Design test: "If a feature rewards stationary play without meaningful commitment cost, redesign it so movement is always the stronger answer."*

### Anti-Pillars (What This Game Is NOT)

- **NOT random unavoidable damage**: Arbitrary death breaks the fear-to-confidence arc. Every hit should be avoidable with the right read.
- **NOT cosmetic companions**: If a companion can be removed without changing any emotional moment, they aren't doing their job.
- **NOT stationary DPS**: Combo chains that require standing still are not this game. Single attacks that incentivize repositioning are.
- **NOT telegraphed mastery**: The game should not tell players they're improving. They should feel it.
- **NOT safe gear progression**: The thrill of the enhancement roll — the 10% scroll, the chaos scroll — is a core memory. Gear stakes must feel real.

---

## Inspiration and References

| Reference | What We Take | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| **MapleStory** | Side-scrolling movement fluidity, class job advancement, gear enhancement gambling, sense of world adventure, music identity | Soulslike combat depth instead of spam-friendly combat; darker atmospheric tone | Proves the side-scrolling ARPG format has passionate players; gear gambling creates memorable moments |
| **Dark Souls** | Telegraphed enemy attacks, companion bonds under pressure, strategic patience | 2D side-scrolling instead of 3D; faster movement pace; companion AI instead of multiplayer | Proves tactical patience and companion bonds create the strongest emotional memories |
| **Sekiro: Shadows Die Twice** | Combat as rhythm, parry as music, composure under pressure as the skill to learn | Roll + parry hybrid instead of pure deflect; MapleStory speed instead of grounded pace | The "rhythm game" mental model is the single most important insight about why this combat will feel unique |
| **Bloodborne** | Fear-to-confidence arc, aggressive-or-die design, boss-as-puzzle | No rally mechanic; stamina governs defense not offense; companions can heal | Proves the fear arc is emotionally transformative when executed correctly |
| **Hollow Knight** | Difficult but fair, precise 2D combat, moody atmospheric world, tight controls | Classes and progression depth; companions; gear system | Market proof: 3M+ sales for challenging 2D action; "difficult but fair" is achievable in 2D |
| **Dead Cells** | Responsive dodge feel, tight combat controls, satisfying hit feedback | Persistent world instead of roguelike; Soulslike bosses instead of procedural | Proves responsive 2D combat feel is achievable and market-validated |
| **Diablo** | Dungeon progression loop, gear chase, party vibes | 2D side-scrolling instead of top-down; Soulslike combat instead of ARPG spam | Validates the dungeon-gate progression structure and loot reward loop |

**Non-game inspirations**: Martial arts philosophy (composure as a skill, not a trait); rhythm music (combat as performance, not reaction); the emotional arc of sports training narratives (terror → discipline → mastery).

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18–35 |
| **Gaming experience** | Mid-core to hardcore |
| **Time availability** | 30–60 minute sessions on weeknights; longer weekend runs |
| **Platform preference** | PC (Steam) |
| **Current games they play** | Hollow Knight, Dead Cells, Elden Ring, Path of Exile |
| **What they're looking for** | A 2D action game with the depth of a Soulslike and the rewarding ARPG progression loop — the feeling of genuine mastery, not just number increases |
| **What would turn them away** | Cheap unavoidable deaths; companions that just stand around; pay-to-win gear; combo chains that reward standing still |

---

## Visual Identity Anchor

**Direction: Vibrant Dark Fantasy**

Characters are immediately readable against atmospheric environments — contrast serves combat legibility above all else.

**One-line visual rule**: The hero must always pop against the world; if a character or enemy attack is hard to read, the environment is wrong, not the character.

**Supporting visual principles**:

1. *Silhouette clarity over detail* — Character and enemy silhouettes follow MapleStory's bold, readable proportions. Attack animations must be legible at a glance. Busy backgrounds never compete with combat readability. Design test: "Can a new player identify the enemy attack type from 3 meters away in one second? If not, simplify the silhouette."

2. *Atmospheric environments, saturated characters* — Backgrounds are muted, detailed, painterly (deep greens, grays, dark stone, moody lighting). Characters and combat VFX use a higher saturation palette (vivid sword glints, bright magic, punchy hit effects). The contrast is intentional — it creates natural focus on the action. Design test: "Does the character/enemy pop off the background in a screenshot? If not, desaturate the background or increase character contrast."

3. *Sound-first feedback design* — Every combat action has a distinctive audio signature before it has a visual polish pass. The parry click, the stagger crack, the burst window chime are designed before the animations around them. Design test: "Can a player understand what just happened with the screen blurred? If not, add an audio cue."

**Color philosophy**: Muted, desaturated backgrounds (deep earth tones, dark stone, forest shadow) with high-saturation character and effect colors (bright weapon highlights, vivid class skill effects, saturated health/stagger UI). Enemies use a muted-but-readable palette — they belong to the world; the player character does not, and that contrast communicates agency.

*This section seeds the art bible. Full visual specification is done via `/art-bible`.*

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Engine** | Godot 4.6 (GDScript) — configured. Best-in-class 2D tooling, MIT license, Jolt physics default |
| **Key Technical Challenges** | Parry hitbox precision (frame-accurate timing with Jolt physics); companion AI with emergent rescue behavior (state machine complexity); gear enhancement probability system with satisfying feedback |
| **Art Style** | Vibrant Dark Fantasy — 2D sprite work, MapleStory-readable characters, Dark Souls atmospheric backgrounds |
| **Art Pipeline Complexity** | Medium — custom 2D sprites with frame-by-frame combat animation; fully defined in `/art-bible` |
| **Audio Needs** | Music-heavy + combat-feedback-critical. MapleStory-inspired melodic themes; Soulslike atmospheric soundscape; every combat action has a distinctive audio cue |
| **Networking** | None |
| **Content Volume** | Prototype: 1 room, 1 enemy; Full game: 5+ regions, 4 class paths, 10+ enemy types, 5+ bosses, companion roster |
| **Procedural Systems** | Handcrafted content preferred (per design philosophy); procedural dungeons TBD |

---

## Risks and Open Questions

### Design Risks

- Combat feel is the #1 risk — parry timing must be tight enough to feel skillful and forgiving enough not to feel cheap. There is no formula for this; it requires iteration.
- Companion AI emotional moments may be difficult to create organically. Scripted moments could feel hollow; emergent ones require sophisticated AI.
- Difficulty curve: balancing punishing challenge with fair progression is delicate. Wrong tuning alienates both Soulslike veterans and MapleStory nostalgics.

### Technical Risks

- Frame-accurate hitbox/hurtbox precision in Godot 4.6 with Jolt physics — parry window behavior must be deterministic and testable.
- Companion AI state machine that produces genuine rescue moments — complexity grows fast, requires dedicated architecture design.
- Animation state machine scope — 4 classes × weapon types × enemy behaviors grows quickly; modular design required from prototype.

### Market Risks

- 2D Soulslike market is active but not saturated; differentiation through the MapleStory DNA and companion system must be clear in marketing.
- MapleStory fans and Soulslike fans are overlapping but distinct audiences — the game must signal to both without alienating either.
- Solo dev timeline means 3–5 years to full release; genre competition will evolve during development.

### Scope Risks

- Full vision is 3–5 years of focused solo work — scope discipline is the single greatest ongoing risk.
- Art pipeline not yet defined (pixel art vs. HD-2D within Vibrant Dark Fantasy direction); `/art-bible` resolves this.
- Companion AI complexity is unprototyped — may require significant design revision after first spike.

### Open Questions

- Does the parry timing feel fun at 8, 10, or 12 frames? → **Answered by combat prototype.**
- Can companion AI create genuine unscripted emotional rescue moments? → **Answered by companion AI spike (pre-production).**
- Exact art style execution within Vibrant Dark Fantasy? → **Answered by `/art-bible`.**
- Death penalty: lose currency / lose progress / both / none? → **Answered by prototype playtesting.**
- World structure: hub-and-dungeon vs. interconnected world? → **Answered by vertical slice design phase.**
- Healing system: Estus-style / consumables / companion healing / regeneration? → **Answered during systems design phase.**

---

## MVP Definition

**Core hypothesis**: "Players find the core combat loop — reading enemy patterns, parrying, dodging, and triggering stagger breaks — engaging and want to play more after 15 minutes."

**Required for MVP**:
1. Player movement: run, jump, facing direction, camera follow
2. Basic attack with hitbox, damage application, hit feedback
3. Stamina system governing dodge roll (I-frames) and shield parry
4. Shield parry with narrow timing window, success/failure states, stagger buildup on success
5. Visible enemy stagger bar, stagger break state, burst damage window
6. Armored Knight enemy with telegraphed Light Slash and Heavy Strike attacks, readable wind-up animations
7. Player and enemy health system with death states

**Explicitly NOT in MVP**:
- Inventory or gear system
- Multiple classes
- Companion system
- Quest system
- Level exploration or world map
- Save/load system
- Skill trees or class abilities

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **Prototype** | Castle Training Hall, Warrior, Armored Knight | Movement, attack, dodge/parry, stagger, HP, death state | 1–3 months |
| **Vertical Slice** | 1 full region, 2–3 enemies, 1 boss, 1 companion | Prototype + class skills, companion AI, basic gear drops | 4–9 months |
| **Early Access** | 3 regions, 2–3 classes, companion party system, gear enhancement | All VS features + progression, world hub, multiple bosses | 1.5–3 years |
| **Full Game** | All regions, all class paths, full companion roster, complete gear system, story | Complete game, polished | 3–5 years |

---

## Next Steps

- [x] Engine configured — Godot 4.6, GDScript (`/setup-engine` complete)
- [ ] **Run `/prototype combat-feel`** — validate the combat loop is fun before writing any GDDs. This is the highest-priority next step.
- [ ] Run `/art-bible` — define the Vibrant Dark Fantasy visual identity in full before asset production begins
- [ ] Run `/design-review design/gdd/game-concept.md` — validate concept completeness
- [ ] Decompose concept into systems (`/map-systems`) — use prototype learnings to inform system priorities
- [ ] Author per-system GDDs (`/design-system [system]`) — combat, companion, progression, gear
- [ ] Plan technical architecture (`/create-architecture`)
- [ ] Validate architecture (`/architecture-review`)
- [ ] Phase gate (`/gate-check`) before committing to production
