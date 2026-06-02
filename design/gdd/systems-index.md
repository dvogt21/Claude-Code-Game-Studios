# Systems Index: Ashen Maple

> **Status**: Draft
> **Created**: 2026-05-28
> **Last Updated**: 2026-05-28
> **Source Concept**: design/gdd/game-concept.md
> **Technical Director Review (TD-PHASE-GATE)**: CONCERNS (accepted) 2026-05-28 — Stagger System / Skills & Abilities / Companion Recruitment reclassified to Feature layer per review.

---

## Overview

Ashen Maple is a 2D Action RPG / Soulslike with MapleStory-inspired class progression,
companion AI, and gear enhancement. Its mechanical scope centers on a real-time combat
loop (parry → stagger → burst) that scales into class specialization, companion synergy,
and high-stakes gear gambling. The game is built on a foundation of precisely-defined
stats and inputs, layered with gameplay systems that create the fear-to-confidence arc,
and topped with progression and economy systems that sustain long-term investment.
Design proceeds from Foundation inward — every system is defined before the systems
that depend on it.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Character Stats | Core | MVP | Approved | design/gdd/character-stats.md | *(none)* |
| 2 | Input & Controls | Core | MVP | Approved | design/gdd/input-and-controls.md | *(none)* |
| 3 | Scene Management | Core | MVP | Not Started | — | *(none)* |
| 4 | Save & Load | Core | Vertical Slice | Not Started | — | *(none)* |
| 5 | Movement | Gameplay | MVP | Approved | design/gdd/movement.md | Input & Controls, Character Stats |
| 6 | Health & Death | Gameplay | MVP | Approved | design/gdd/health-and-death.md | Character Stats |
| 7 | Stamina | Gameplay | MVP | Not Started | — | Character Stats, Input & Controls |
| 8 | Inventory & Equipment | Economy | Vertical Slice | Not Started | — | Character Stats |
| 9 | Combat | Gameplay | MVP | Not Started | — | Movement, Health & Death, Stamina, Input & Controls |
| 10 | Enemy AI | Gameplay | MVP | Not Started | — | Movement, Health & Death |
| 11 | Checkpoint & Respawn | Gameplay | MVP | Not Started | — | Health & Death, Scene Management |
| 12 | Companion AI | Gameplay | Vertical Slice | Not Started | — | Movement, Health & Death, Enemy AI |
| 13 | Loot & Drop Tables | Economy | Vertical Slice | Not Started | — | Enemy AI, Inventory & Equipment |
| 14 | Class & Leveling | Progression | Vertical Slice | Not Started | — | Character Stats, Combat |
| 15 | Gear Enhancement | Economy | Vertical Slice | Not Started | — | Inventory & Equipment |
| 16 | Stagger System | Gameplay | MVP | Not Started | — | Combat, Enemy AI |
| 17 | Skills & Abilities | Progression | Alpha | Not Started | — | Class & Leveling, Combat, Stamina |
| 18 | Companion Recruitment | Progression | Vertical Slice | Not Started | — | Companion AI |
| 19 | Quest & Journal | Narrative | Full Vision | Not Started | — | NPC & Dialogue, Companion Recruitment, World Structure |
| 20 | HUD | UI | Vertical Slice | Not Started | — | Combat, Health & Death, Stamina, Stagger System, Companion AI |
| 21 | Combat Feedback | UI | MVP | Not Started | — | Combat, Stagger System |
| 22 | Audio Design | Audio | Vertical Slice | Not Started | — | Combat, Stagger System |
| 23 | Menus & Navigation | UI | Vertical Slice | Not Started | — | Save & Load, Input & Controls |
| 24 | World Structure | Meta | Alpha | Not Started | — | Scene Management, Checkpoint & Respawn |
| 25 | NPC & Dialogue | Narrative | Full Vision | Not Started | — | World Structure, Companion Recruitment |
| 26 | Tutorial & Onboarding | Meta | Full Vision | Not Started | — | Combat, Movement |
| 27 | Accessibility | Meta | Full Vision | Not Started | — | Input & Controls, HUD, Audio Design |

---

## Categories

| Category | Description | Ashen Maple Systems |
|----------|-------------|---------------------|
| **Core** | Foundation systems everything depends on | Character Stats, Input & Controls, Scene Management, Save & Load |
| **Gameplay** | Systems that make the game fun | Movement, Health & Death, Stamina, Combat, Stagger System, Enemy AI, Checkpoint & Respawn, Companion AI |
| **Progression** | How the player grows over time | Class & Leveling, Skills & Abilities, Companion Recruitment |
| **Economy** | Resource creation, risk, and consumption | Inventory & Equipment, Loot & Drop Tables, Gear Enhancement |
| **UI** | Player-facing information displays | HUD, Combat Feedback, Menus & Navigation |
| **Audio** | Sound and music systems | Audio Design |
| **Narrative** | Story and dialogue delivery | NPC & Dialogue, Quest & Journal |
| **Meta** | Systems outside the core game loop | World Structure, Tutorial & Onboarding, Accessibility |

---

## Priority Tiers

| Tier | Definition | Ashen Maple Milestone | Design Urgency |
|------|------------|-----------------------|----------------|
| **MVP** | Required for the parry → stagger → burst core loop to function and be testable | Castle Training Hall (first real build, post-prototype) | Design FIRST |
| **Vertical Slice** | Required for one complete region: 2–3 enemies, 1 boss, 1 companion, class identity, gear drops | VS / Demo | Design SECOND |
| **Alpha** | All gameplay features present in rough form; multiple classes, multiple regions | Alpha milestone | Design THIRD |
| **Full Vision** | Polish, narrative, tutorial, accessibility, content-complete | Beta / Release | Design as needed |

---

## Dependency Map

### Foundation Layer (no dependencies — design first)

1. **Character Stats** — the stat vocabulary (HP, stamina, ATK, DEF, speed, poise, parity window) every other system reads
2. **Input & Controls** — the action map (attack, dodge, parry, interact, navigate) every control-consuming system references
3. **Scene Management** — the scene loading and room transition framework all level design plugs into
4. **Save & Load** — the persistence framework; data contract is filled by gameplay systems, but the mechanism is foundational

### Core Layer (depends on Foundation only)

5. **Movement** — depends on: Input & Controls, Character Stats
6. **Health & Death** — depends on: Character Stats
7. **Stamina** — depends on: Character Stats, Input & Controls
8. **Inventory & Equipment** — depends on: Character Stats (stat modifiers calculated from gear)

### Feature Layer (depends on Core)

9. **Combat** — depends on: Movement, Health & Death, Stamina, Input & Controls
10. **Enemy AI** — depends on: Movement (pathfinding), Health & Death
11. **Checkpoint & Respawn** — depends on: Health & Death, Scene Management
12. **Companion AI** — depends on: Movement, Health & Death, Enemy AI
13. **Loot & Drop Tables** — depends on: Enemy AI (drop on death), Inventory & Equipment
14. **Class & Leveling** — depends on: Character Stats, Combat (levels scale combat stats)
15. **Gear Enhancement** — depends on: Inventory & Equipment
16. **Stagger System** — depends on: Combat, Enemy AI *(authoritative gameplay state, not presentation — stagger break gates the burst-damage window; accumulation interacts with both attack output and enemy poise)*
17. **Skills & Abilities** — depends on: Class & Leveling, Combat, Stamina
18. **Companion Recruitment** — depends on: Companion AI

### Presentation Layer (depends on Features)

19. **Quest & Journal** — depends on: NPC & Dialogue, Companion Recruitment, World Structure
20. **HUD** — depends on: Combat, Health & Death, Stamina, Stagger System, Companion AI
21. **Combat Feedback** — depends on: Combat, Stagger System
22. **Audio Design** — depends on: Combat, Stagger System (SFX trigger hooks)
23. **Menus & Navigation** — depends on: Save & Load, Input & Controls

### Polish Layer (depends on everything)

24. **World Structure** — depends on: Scene Management, Checkpoint & Respawn
25. **NPC & Dialogue** — depends on: World Structure, Companion Recruitment
26. **Tutorial & Onboarding** — depends on: Combat, Movement (all MVP systems)
27. **Accessibility** — depends on: Input & Controls, HUD, Audio Design

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Character Stats | MVP | Foundation | game-designer, systems-designer | S |
| 2 | Input & Controls | MVP | Foundation | game-designer, ux-designer | S |
| 3 | Scene Management | MVP | Foundation | game-designer, engine-programmer | S |
| 4 | Movement | MVP | Core | game-designer, gameplay-programmer | S |
| 5 | Health & Death | MVP | Core | game-designer, systems-designer | S |
| 6 | Stamina | MVP | Core | game-designer, systems-designer | S |
| 7 | Enemy AI | MVP | Feature | game-designer, ai-programmer | M |
| 8 | Combat | MVP | Feature | game-designer, gameplay-programmer | L |
| 9 | Stagger System | MVP | Feature | game-designer, gameplay-programmer | M |
| 10 | Checkpoint & Respawn | MVP | Feature | game-designer | S |
| 11 | Combat Feedback | MVP | Presentation | game-designer, technical-artist | M |
| 12 | Inventory & Equipment | Vertical Slice | Core | game-designer, systems-designer | M |
| 13 | Class & Leveling | Vertical Slice | Feature | game-designer, systems-designer | L |
| 14 | Companion AI | Vertical Slice | Feature | game-designer, ai-programmer | L |
| 15 | Loot & Drop Tables | Vertical Slice | Feature | game-designer, economy-designer | M |
| 16 | Companion Recruitment | Vertical Slice | Feature | game-designer, narrative-director | M |
| 17 | Save & Load | Vertical Slice | Foundation | game-designer, engine-programmer | S |
| 18 | Gear Enhancement | Vertical Slice | Feature | game-designer, economy-designer | M |
| 19 | HUD | Vertical Slice | Presentation | game-designer, ux-designer, ui-programmer | M |
| 20 | Audio Design | Vertical Slice | Presentation | audio-director, sound-designer | M |
| 21 | Menus & Navigation | Vertical Slice | Presentation | ux-designer, ui-programmer | S |
| 22 | Skills & Abilities | Alpha | Feature | game-designer, gameplay-programmer | L |
| 23 | World Structure | Alpha | Polish | game-designer, level-designer | M |
| 24 | NPC & Dialogue | Full Vision | Narrative | narrative-director, game-designer | L |
| 25 | Quest & Journal | Full Vision | Narrative | narrative-director, game-designer | M |
| 26 | Tutorial & Onboarding | Full Vision | Meta | game-designer, ux-designer | M |
| 27 | Accessibility | Full Vision | Meta | ux-designer, accessibility-specialist | M |

*Effort: S = 1 session (~2–4 hrs), M = 2–3 sessions, L = 4+ sessions*

---

## Circular Dependencies

None detected. All dependency chains are acyclic and resolve to the Foundation layer.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| **Enemy AI** | Technical + Design | Frame-accurate wind-up telegraphs must be perceptually readable AND deterministic in Jolt physics; hitbox precision is critical for "fair" feel | Combat prototype (PROCEED verdict) validated basic approach; document hitbox layer contract in ADR before first implementation |
| **Companion AI** | Design + Scope | Emergent rescue moments require sophisticated behavioral AI — scripted rescues feel hollow; emergent ones require state machine complexity that grows fast | Requires a dedicated pre-production spike before VS commitment; design Companion AI GDD before implementation begins |
| **Gear Enhancement** | Design | Probability tuning is subjective — "scary but fair" vs. "RNG frustrating" has no formula; wrong tuning alienates the audience this mechanic targets | Paper-prototype scroll probability tables before implementation; reference MapleStory scroll data as historical baseline |
| **Stagger System** | Design | Accumulation rate must feel earned (not trivial) but reachable (not hopeless) — wrong balance breaks "Read the Rhythm" pillar | Combat prototype validated basic feel; define stagger accumulation formula in GDD with explicit tuning range |
| **Class & Leveling** | Scope | 4 base classes × specializations = large content volume; class skills require separate design work per class | Design Warrior first as template; treat other classes as derivatives; defer specializations to Alpha |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 27 |
| Design docs started | 2 |
| Design docs reviewed | 1 |
| Design docs approved | 1 |
| MVP systems designed | 1 / 11 |
| Vertical Slice systems designed | 0 / 10 |

---

## Next Steps

- [ ] Design MVP-tier systems in order (run `/design-system [system-name]`)
- [ ] Start with **Character Stats** (design order #1) — unblocks everything else
- [ ] Run `/design-review design/gdd/[system].md` after each GDD is complete
- [ ] Run `/gate-check pre-production` when all MVP GDDs are authored and reviewed
- [ ] Spike **Companion AI** in pre-production before committing VS scope
