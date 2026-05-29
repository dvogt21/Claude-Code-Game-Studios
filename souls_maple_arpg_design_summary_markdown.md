# 2D Action RPG Design Summary

## Project Overview

This document summarizes the current vision, gameplay philosophy, technical architecture, design decisions, combat systems, implementation priorities, and unresolved questions for the game project.

This document is intended to be used as a foundational reference for future development discussions and implementation planning, especially with Claude Code.

---

# High-Level Game Concept

## Core Idea

The game is a:

- Single-player
- 2D side-scrolling action RPG
- Inspired by MapleStory progression and movement
- With Souls-like combat philosophy
- Diablo-style dungeon progression
- Party-based companion mechanics
- Character class advancement system
- Equipment progression with elemental/status enhancements

The intended gameplay experience is:

- Fast-paced and fluid
- Strategic and punishing
- Skill-based rather than stat-based
- Rewarding movement, timing, positioning, and patience

The player creates a character, chooses a class path through leveling progression, explores the world, completes quests, recruits NPC companions, clears dungeons, acquires gear, and unlocks new regions.

---

# Core Gameplay Loop

The currently defined gameplay loop is:

1. Create a character
2. Explore the world
3. Gain experience and level up
4. Unlock a base class
5. Progress into advanced specializations later
6. Complete quests and dungeons
7. Recruit NPC companions
8. Improve gear and weapon enhancements
9. Defeat difficult bosses
10. Unlock new regions and harder content
11. Repeat progression loop

The intended long-term gameplay feel is:

- Exploration
- Tactical combat
- Build progression
- Dungeon mastery
- Mechanical skill expression

---

# Primary Inspirations

## MapleStory

Used primarily for:

- Side-scrolling movement
- Class progression structure
- Job advancements
- Fast attack pacing
- Character identity
- World exploration structure

## Dark Souls / Bloodborne

Used primarily for:

- Combat philosophy
- Dodge timing
- I-frame mechanics
- Enemy telegraphing
- Parry systems
- Stagger mechanics
- Punishing but fair encounters
- Patience-based boss fights

## Diablo

Used primarily for:

- Dungeon progression
- Loot acquisition loop
- Region unlocking structure
- Equipment progression

## Hollow Knight / Dead Cells

Used primarily for:

- Responsive combat feel
- Mobility and dodge responsiveness
- Tight combat controls

---

# Combat Philosophy

## Core Combat Identity

The combat system is intended to combine:

- MapleStory speed
- Souls-like tactical combat
- High player mobility
- Positioning-based gameplay
- Skill expression through timing

The combat is intentionally NOT intended to be:

- Pure button mashing
- Stationary DPS gameplay
- Combo-heavy grounded fighting

Instead, the game should reward:

- Constant movement
- Dodging
- Positioning
- Timing
- Reading enemy attacks
- Patience
- Precision

---

# Combat Rules

## Player Combat Philosophy

The player can attack rapidly, but:

- Standing still should be dangerous
- Poor positioning should be punished
- Greedy attacking should result in damage taken

The combat system is intended to create a natural rhythm of:

- Move
- Attack
- Dodge
- Reposition
- Counterattack
- Build stagger
- Burst during stagger windows

---

# Current Combat Design Decisions

## Movement Style

### DECISION

MapleStory-style 2D side-scrolling movement.

### Includes

- Left/right movement
- Jumping
- Platforming support
- Side-scrolling combat arenas

### Does NOT Include

- Wall climbing
- Metroidvania traversal focus

### WHY

The goal is to preserve MapleStory's recognizable movement identity while layering more strategic combat on top.

The game should feel agile and fluid rather than grounded and heavy.

---

# Dodge System

## DECISION

Rolling dodge system.

### Current Plan

- Roll-based dodge
- Invincibility frames during dodge
- Stamina cost
- Moderate commitment window

### Future Possibility

Some classes may eventually use dash mechanics instead.

### WHY

Rolling fits the Warrior prototype and creates Souls-like combat timing.

Rolling also reinforces:

- Commitment
- Risk management
- Positioning

while still preserving movement fluidity.

---

# Invincibility Frames (I-Frames)

## DECISION

Rolling grants temporary invulnerability.

### WHY

This is a core skill-expression mechanic.

The player should:

- Learn enemy timing
- Dodge through attacks
- Use timing instead of tanking damage

This creates a fair but punishing combat system.

---

# Parry System

## DECISION

High-risk shield parry.

### Current Plan

- Shield-based parry animation
- Small active timing window
- Failed parry leaves player vulnerable
- Successful parry heavily damages stagger meter
- NPCs cannot parry

### WHY

The parry system is intended to:

- Reward mastery
- Create satisfying combat moments
- Enable stagger-based burst windows
- Differentiate skilled play

Shield parry was chosen because:

- Easier readability
- Easier animation clarity
- Easier player communication
- Cleaner prototype implementation

---

# Stagger System

## DECISION

Visible stagger bar.

### Current Plan

- Enemies have a visible stagger meter
- Attacks build stagger gradually
- Parries build large stagger amounts
- When stagger breaks:
  - Enemy enters vulnerable state
  - Enemy becomes stunned
  - Enemy takes bonus damage

### WHY

This is one of the central emotional payoffs of combat.

The intended player experience is:

- Enemy initially feels dangerous and tanky
- Player survives patiently
- Player reads attack patterns
- Player builds stagger strategically
- Stagger breaks
- Massive burst damage window occurs

This creates tension and payoff.

Visible stagger bars were chosen because:

- Easier readability in a fast-paced ARPG
- Stronger visual feedback
- More satisfying progression toward vulnerability

---

# Attack System

## DECISION

Single attacks rather than combo chains.

### WHY

The game intentionally does not want to encourage:

- Standing still
- Long grounded combo loops
- Static DPS gameplay

Single attacks encourage:

- Repositioning
- Movement between attacks
- Tactical spacing
- Defensive awareness

This aligns more closely with Souls-style combat pacing.

Combos may be revisited later.

---

# Stamina System

## DECISION

The game WILL use stamina.

### Current Plan

Stamina primarily governs:

- Dodging
- Parrying
- Defensive options

Basic attacks currently do NOT consume stamina.

### WHY

The stamina system is intended to create decision-making around:

- Defensive timing
- Risk management
- Resource commitment

However, attacks were intentionally excluded from stamina cost because:

- The game already discourages stationary spam through positioning
- Attacks should remain responsive
- Early combat should feel fluid
- Excessive stamina restrictions could make combat feel sluggish

The intended question for the player is:

"Do I dodge, parry, or hold position?"

NOT:

"Why can't I attack anymore?"

---

# Camera Design

## DECISION

Maple-style side-follow camera.

### Current Plan

- Camera smoothly follows player
- Fixed side-scrolling framing
- No arena lock-on system initially

### WHY

The goal is to preserve the side-scrolling ARPG feel.

Boss-specific cinematic camera systems may be added later.

---

# Combat Encounter Philosophy

## DECISION

Primarily Souls-style enemy counts.

### Current Philosophy

Most encounters should contain:

- 1-6 meaningful enemies

rather than:

- Massive mindless mob swarms

### WHY

This supports:

- Readable combat
- Tactical gameplay
- Positioning
- Dodge/parry mechanics
- Enemy telegraphing

Enemies should feel dangerous individually.

---

# Enemy Density Philosophy

## Current Plan

Three encounter categories exist conceptually.

### 1. Duel Encounters

Small-scale fights.

Purpose:

- Skill checks
- Timing mastery
- Parry practice
- Elite enemy fights

### 2. Tactical Packs

Small groups of meaningful enemies.

Purpose:

- Positioning
- Target prioritization
- Tactical movement

### 3. Mob Swarms

Rare specialized encounters.

Purpose:

- Puzzle-like combat
- Environmental interaction
- Strategic crowd management

Large swarms should NEVER become mindless enemy spam.

They should instead be intentionally designed encounters.

---

# Enemy Design Philosophy

## DECISION

Enemies must use telegraphed attacks.

### WHY

Combat is intended to be:

- Fair
- Learnable
- Skill-based

Enemy attacks should include:

- Wind-up
- Active attack frames
- Recovery windows

This enables:

- Dodging
- Parrying
- Punishing mistakes
- Learning patterns

The design intentionally avoids:

- Instant unavoidable damage
- Enemies simply walking into the player
- Non-readable attacks

---

# Class Design Philosophy

## Current Planned Archetypes

### Warrior

Role:

- Durable melee fighter
- Strong parry specialist
- Strong stagger generation

Playstyle:

- Frontline duelist
- Defensive timing
- Heavy punish windows

### Thief

Role:

- Agile melee/ranged hybrid
- Critical damage
- Weak spot specialist

Playstyle:

- Dodge-heavy
- Back attacks
- Fast repositioning

### Archer

Role:

- Long-range precision attacker
- Weak spot exploitation

Playstyle:

- Kiting
- Positioning
- Counter-attacking

### Mage

Role:

- High burst damage
- Area control

Playstyle:

- Spell timing
- Vulnerability management
- Punishing openings

---

# Weak Spot System

## Current Concept

Ranged classes may gain bonus damage through:

- Weak-point targeting
- Back attacks
- Counter-hit opportunities
- Attacking after enemy recovery windows

### WHY

Ranged classes are intended to:

- Avoid direct danger more easily
- Be physically fragile
- Require precision and timing to maximize damage

This prevents ranged gameplay from becoming passive.

---

# Party System

## Current Vision

The player can recruit NPC companions.

### Current Planned Rules

- Maximum party size: 4
- NPCs are AI-controlled
- NPCs support the player
- NPCs cannot parry

### Potential Roles

- Tank
- Healer
- Support
- DPS

### WHY

The party system is intended to:

- Expand combat strategy
- Enable build experimentation
- Create RPG progression depth

However:

The player should remain the primary skill expression source.

NPCs should support—not replace—player mastery.

---

# NPC Recruitment

## Current Plan

NPC companions may be unlocked through:

- Quests
- Story progression
- Dungeon completion
- Gacha system

## Gacha Philosophy

The gacha system is NOT intended to be pay-to-win.

It is intended as:

- A progression/reward system
- A collection mechanic
- A party-building system

Monetization plans are currently undefined.

---

# Progression Structure

## Current Plan

The world progresses through:

- Dungeon completion
- Area unlocking
- Equipment upgrades
- Character leveling

### Example Structure

Starter Area
→ Forest
→ Ruined City
→ Volcanic Region
→ etc.

### WHY

This creates:

- Clear progression goals
- Exploration rewards
- Difficulty scaling
- Long-term progression pacing

---

# Class Advancement System

## Current Vision

Inspired heavily by MapleStory.

### Planned Structure

Example:

Beginner
→ Warrior / Mage / Archer / Thief
→ Advanced Specializations

### WHY

The class advancement system creates:

- Long-term identity
- Build progression
- Replayability
- Meaningful milestones

Specific class trees are not yet designed.

---

# Gear System Philosophy

## Current Vision

The gear system is inspired more by Dark Souls than MapleStory.

### Current Plan

Weapons and gear may include:

- Upgrade levels
- Elemental infusions
- Status effects
- Enhancement paths

### WHY

The system is intended to:

- Encourage build experimentation
- Support class diversity
- Create long-term progression
- Avoid simplistic stat-only scaling

Traditional Maple-style scrolling systems are NOT the intended primary progression system.

---

# Dungeon Philosophy

## Current Plan

Dungeons are intended to be:

- Core progression content
- Sources of gear and upgrades
- Sources of major boss fights
- Gateways to new regions

### Dungeon Design Philosophy

Dungeons should include:

- Combat pacing variety
- Tactical encounters
- Mini-bosses
- Environmental storytelling
- Optional exploration

Procedural generation has NOT been finalized.

Current leaning appears to favor handcrafted content first.

---

# Technical Architecture Philosophy

## Current Direction

The project is intended to use:

- Unity
- C#
- Modular component-based architecture
- Data-driven design

### Planned Architecture Principles

- Separation of responsibilities
- Modular systems
- Expandable combat systems
- Reusable enemy behaviors
- Flexible data structures

---

# Current Prototype Scope

## IMPORTANT DESIGN DECISION

The first prototype is intentionally VERY SMALL.

### Current Prototype Goal

A single playable combat room.

### Current Prototype Environment

Castle Training Hall.

### Current Prototype Enemy

Armored Knight.

### Current Prototype Goal

Prove the combat system is fun.

NOT:

- Build the whole RPG immediately
- Build quests
- Build classes
- Build inventory systems
- Build world exploration

### WHY

The combat system is the heart of the game.

If combat is not satisfying:

- Nothing else matters
- Expansion becomes wasteful

Therefore:

The first milestone is strictly validating combat feel.

---

# Current Prototype Content

## Player Prototype

Current prototype class:

- Warrior

Current abilities:

- Movement
- Jump
- Single attack
- Roll dodge
- Shield parry

---

# Current Prototype Enemy

## Armored Knight

### Planned Behavior

- Walk toward player
- Use readable melee attacks
- Have attack windups
- Be parryable
- Use stagger system

### Planned Attacks

#### Light Slash

- Faster
- Lower damage
- Easier dodge test

#### Heavy Strike

- Longer windup
- Higher damage
- Better parry opportunity

### WHY

The armored knight is ideal because:

- Easy readability
- Supports parry learning
- Supports stagger gameplay
- Fits the training hall environment
- Tests melee combat fundamentals

---

# Prototype Environment

## Castle Training Hall

### WHY

This environment was chosen because:

- Simple to graybox
- Easy to prototype quickly
- Fits melee combat naturally
- Allows focused combat testing
- Minimal environmental complexity

The prototype intentionally avoids:

- Complex traversal
- Environmental hazards
- Exploration distractions

---

# Current Prototype Combat Loop

The intended prototype combat loop is:

1. Enemy attacks
2. Player reads telegraph
3. Player dodges or parries
4. Player lands punish attack
5. Stagger builds gradually
6. Stagger breaks
7. Enemy becomes vulnerable
8. Massive damage window opens
9. Enemy recovers
10. Loop repeats

This loop is considered one of the core emotional pillars of the game.

---

# Current Prototype Systems

## Planned Prototype Systems

### Included

- Movement
- Jumping
- Basic attack
- Stamina
- Dodge roll
- I-frames
- Shield parry
- Enemy AI
- Health system
- Stagger system
- Visible stagger UI
- Enemy HP
- Player HP
- Death states

### Explicitly Excluded (For Now)

- Inventory system
- Gear complexity
- Quest system
- NPC companions
- Gacha systems
- Save/load
- Skill trees
- Multiple classes
- Crafting
- Advanced world exploration
- Elemental systems

### WHY

Prototype scope is intentionally minimized to:

- Reduce complexity
- Validate combat quickly
- Avoid development paralysis
- Enable iteration

---

# Current Technical Architecture

## Planned Script Separation

### Player Systems

- PlayerController
- PlayerCombat
- PlayerHealth
- PlayerStamina

### Enemy Systems

- EnemyController
- EnemyCombat
- EnemyHealth

### Combat Systems

- Hitbox
- Hurtbox
- HitData

### WHY

The architecture intentionally separates:

- Movement
- Combat
- Health
- AI
- Resource systems

to avoid giant unmaintainable scripts.

---

# Current Unity Architecture Direction

## Current Planned Structure

### Folder Structure

Assets/
  Scenes/
  Scripts/
  Prefabs/
  Animations/
  Art/
  ScriptableObjects/

### WHY

The project is intended to remain scalable and maintainable from the start.

---

# Current Prototype Milestones

## Milestone 1

Player movement.

### Success Criteria

- Run
- Jump
- Camera follow
- Facing direction

---

## Milestone 2

Basic attack system.

### Success Criteria

- Attack animation
- Hitbox activation
- Damage application

---

## Milestone 3

Stamina + dodge.

### Success Criteria

- Roll consumes stamina
- I-frames function
- Stamina regenerates properly

---

## Milestone 4

Parry system.

### Success Criteria

- Parry timing window exists
- Failed parry punish exists
- Successful parry creates stagger pressure

---

## Milestone 5

Armored knight enemy.

### Success Criteria

- Enemy AI functions
- Telegraphs readable
- Combat loop works

---

## Milestone 6

Stagger system.

### Success Criteria

- Visible stagger bar
- Stagger break state
- Burst damage window

---

# Major Unresolved Questions

The following systems are NOT finalized and require future design work.

## World Structure

Unknowns:

- Fully interconnected world?
- Region-based progression?
- Open world?
- Hub-and-dungeon structure?

---

## Story and Narrative

Unknowns:

- Setting lore
- Main conflict
- Tone
- Factions
- World history
- Player role in world

---

## Art Direction

Unknowns:

- Pixel art vs HD 2D
- Animation style
- Visual tone
- Character proportions
- UI style

---

## Multiplayer

Current assumption:

Single-player only.

Not formally finalized.

---

## Procedural Generation

Unknowns:

- Procedural dungeons?
- Handcrafted dungeons?
- Hybrid system?

---

## Economy Design

Unknowns:

- Currency systems
- Upgrade materials
- Trading
- Crafting

---

## Gear Depth

Unknowns:

- Number of weapon types
- Armor systems
- Set bonuses
- Stat scaling
- Infusion systems

---

## Companion AI Complexity

Unknowns:

- AI behavior customization
- Companion commands
- Positioning logic
- Threat management

---

## Class Advancement Details

Unknowns:

- Number of classes
- Specialization trees
- Skill acquisition pacing
- Build customization depth

---

## Difficulty Philosophy

Partially defined.

Current direction:

- Difficult but fair
- Skill-based
- Punishing greed
- Rewarding mastery

Still unresolved:

- Death penalties
- Checkpoint systems
- Healing economy
- Boss retry pacing

---

# Extremely Important Design Philosophy

## Core Priority

The project prioritizes:

COMBAT FEEL FIRST.

This is the most important decision made so far.

Everything else is secondary until combat feels satisfying.

This philosophy is the reason the prototype intentionally excludes:

- Large content scope
- RPG systems
- Narrative complexity
- World systems
- Economy systems

The current strategy is:

1. Validate combat feel
2. Expand vertically
3. Add progression systems
4. Add content
5. Scale the world

rather than:

trying to build the entire game immediately.

---

# Questions Requiring Clarification

The following questions still require explicit answers before full production planning.

## 1. Art Direction

What visual style is intended?

Examples:

- Pixel art?
- HD-2D?
- Anime-inspired?
- Dark fantasy?
- Stylized?
- Semi-realistic?

This affects:

- Animation workload
- Asset pipeline
- Technical scope
- UI design
- Combat readability

---

## 2. World Structure

How should exploration function?

Examples:

- Large interconnected world?
- Region hub progression?
- Dungeon-select structure?
- Metroidvania elements?

This impacts:

- Save systems
- Traversal design
- Streaming/loading
- Progression pacing

---

## 3. Healing System

How should healing work?

Examples:

- Estus-style limited healing?
- Consumables?
- Regeneration?
- Companion healing?

This heavily affects difficulty balance.

---

## 4. Death Penalty

What happens on death?

Examples:

- Lose currency?
- Respawn at checkpoint?
- Recover dropped resources?
- No penalty?

This strongly affects tension.

---

## 5. Checkpoint Structure

How should progression checkpoints work?

Examples:

- Bonfire-style checkpoints?
- Dungeon checkpoints?
- Town returns?

---

## 6. Weapon Variety

What weapon archetypes are planned?

Examples:

- Swords
- Spears
- Greatswords
- Daggers
- Bows
- Magic catalysts

This impacts:

- Animation systems
- Combat depth
- Class identity

---

## 7. Enemy Variety Philosophy

How mechanically different should enemies become?

Examples:

- Mostly stat progression?
- Entirely unique mechanics?
- Puzzle enemies?
- Elite modifiers?

---

## 8. Boss Design Philosophy

How cinematic/mechanical should bosses become?

Examples:

- Souls-style duels?
- MMO mechanics?
- Bullet hell phases?
- Large cinematic monsters?

---

## 9. Platforming Importance

How important should platforming become later?

Currently:

- Present
- Not central

Not fully defined.

---

## 10. Long-Term Session Structure

What should endgame gameplay look like?

Examples:

- Endless dungeons?
- Raid-style bosses?
- Seasonal progression?
- Collection completion?
- Challenge modifiers?

---

# Final Summary

The current game vision is:

A single-player 2D action RPG combining:

- MapleStory movement and progression
- Souls-like tactical combat
- Diablo-style dungeon progression
- Party-based RPG systems
- Skill-based boss encounters

The combat philosophy prioritizes:

- Movement
- Timing
- Dodging
- Parrying
- Stagger mechanics
- Tactical positioning
- Patience and payoff

The current development strategy intentionally focuses on:

- Small prototype scope
- Combat-first development
- Modular architecture
- Fast iteration
- Readable combat

The first prototype is:

- A Warrior
- Fighting an Armored Knight
- Inside a Castle Training Hall
- Using dodge, parry, stamina, and stagger systems

The core goal of the prototype is to validate:

"Does the combat feel satisfying enough to build the entire game around?"

