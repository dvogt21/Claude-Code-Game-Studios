# Review Log: Input & Controls

## Review — 2026-05-31 — Verdict: APPROVED (post-revision)
Scope signal: L
Specialists: game-designer, godot-specialist, ux-designer, qa-lead, systems-designer, creative-director
Blocking items: 9 | Recommended: 10
Summary: Initial verdict was MAJOR REVISION NEEDED due to four incorrect Godot API specifications (is_action_just_pressed in _physics_process, single move action vs. get_vector 4-action requirement, buffer without consumed flag, _unhandled_input for UI Controls), a missing architectural specification for the Stamina/Combat permission model (no data structure defined), a mathematically false preserved-dodge-buffer guarantee (3-frame buffer vs. 21-frame parry animation), an implementation-blocking underspecified rebinding screen, and missing InputMap entries for skill use and companion commands. All 9 blockers resolved in the same session: InputResolver node pattern added as the Stamina/Combat permission mechanism and sole buffer consumer; move action replaced with four sub-actions; buffer writes moved to _input(); _gui_input() corrected; dodge-after-parry guarantee removed and replaced with accurate expiry note; rebinding screen fully specified (conflict policy, capture state machine, required action warning, reset-to-defaults); skill_1, skill_2, companion_command added as placeholder entries; priority table corrected to remove non-bufferable actions. Five additional ACs added (dual-mapping, move magnitude invariant, initialization guard).
Prior verdict resolved: N/A — first review
