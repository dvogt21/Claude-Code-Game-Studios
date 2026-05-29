# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the parry/dodge timing window learnable in ~3 attempts?
# Date: 2026-05-28
extends Node2D

const PLAYER_START := Vector2(320, 580)
const KNIGHT_START := Vector2(940, 580)

var player: CharacterBody2D
var knight: CharacterBody2D
var death_count       := 0
var restart_pending   := false
var restart_timer     := 0.0

# UI
var debug_label       : Label
var parry_alert_label : Label
var death_label       : Label

func _ready() -> void:
	_setup_inputs()
	_build_world()
	_spawn_player()
	_spawn_knight()
	_build_ui()

# ── Input ──────────────────────────────────────────────────────────────────
func _setup_inputs() -> void:
	_bind("move_left",  [KEY_LEFT,  KEY_A])
	_bind("move_right", [KEY_RIGHT, KEY_D])
	_bind("dodge",      [KEY_Z,     KEY_SHIFT])
	_bind("parry",      [KEY_X,     KEY_SPACE])

func _bind(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev       := InputEventKey.new()
		ev.keycode   = k
		InputMap.action_add_event(action, ev)

# ── World ──────────────────────────────────────────────────────────────────
func _build_world() -> void:
	# Background
	var bg       := ColorRect.new()
	bg.color     = Color(0.07, 0.07, 0.11)
	bg.size      = Vector2(1280, 720)
	bg.z_index   = -10
	add_child(bg)

	# Floor visual
	var fv       := ColorRect.new()
	fv.color     = Color(0.2, 0.2, 0.26)
	fv.size      = Vector2(1280, 52)
	fv.position  = Vector2(0, 650)
	add_child(fv)

	# Floor physics body (top surface at y = 650)
	var fb       := StaticBody2D.new()
	var fc       := CollisionShape2D.new()
	var fs       := RectangleShape2D.new()
	fs.size      = Vector2(1280, 52)
	fc.shape     = fs
	fb.add_child(fc)
	fb.position  = Vector2(640, 676)   # centre of the floor rect
	add_child(fb)

# ── Actors ─────────────────────────────────────────────────────────────────
func _spawn_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(load("res://player.gd"))
	player.position = PLAYER_START
	add_child(player)

func _spawn_knight() -> void:
	knight = CharacterBody2D.new()
	knight.set_script(load("res://armored_knight.gd"))
	knight.position = KNIGHT_START
	add_child(knight)
	knight.set("player", player)   # safe: set before first _physics_process

# ── UI ─────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	# Controls hint
	var hint        := Label.new()
	hint.text       = (
		"A / D  or  ← →  : Move\n"
		+ "Z / Shift       : Dodge  (YELLOW = I-frames — attacks pass through you)\n"
		+ "X / Space       : Parry  (GREEN = in parry stance)\n\n"
		+ "Knight colours  :  GRAY = idle/walking    YELLOW = light attack coming\n"
		+ "                   ORANGE = heavy attack coming    RED = attack is LIVE now"
	)
	hint.position   = Vector2(8, 6)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	ui.add_child(hint)

	# "PARRY WINDOW ACTIVE" — appears only when the knight's attack is live
	parry_alert_label          = Label.new()
	parry_alert_label.text     = "!! PARRY WINDOW ACTIVE — press X/Space now !!"
	parry_alert_label.position = Vector2(380, 300)
	parry_alert_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	parry_alert_label.visible  = false
	ui.add_child(parry_alert_label)

	# State readout
	debug_label          = Label.new()
	debug_label.position = Vector2(8, 150)
	debug_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.35))
	ui.add_child(debug_label)

	# Death counter
	death_label          = Label.new()
	death_label.position = Vector2(8, 174)
	death_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	ui.add_child(death_label)

# ── Game loop ──────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if restart_pending:
		restart_timer -= delta
		if restart_timer <= 0.0:
			restart_pending = false
			player.call("reset", PLAYER_START)
			knight.call("reset", KNIGHT_START)
		return

	if bool(player.call("is_dead")) and not restart_pending:
		restart_pending = true
		restart_timer   = 1.2
		death_count    += 1

	_refresh_ui()

func _refresh_ui() -> void:
	parry_alert_label.visible = bool(knight.call("is_attacking"))

	# Map enum ints to readable names without using .keys() (avoids dynamic typing issues)
	var p_names := ["IDLE", "DODGING", "PARRYING", "HIT", "DEAD"]
	var k_names := ["IDLE", "WALKING", "WINDUP_LIGHT", "WINDUP_HEAVY",
					"ATTACKING", "RECOVERY", "STAGGERED"]

	var p_idx: int = int(player.get("state"))
	var k_idx: int = int(knight.get("kstate"))

	debug_label.text = (
		"Player: %s   HP: %d/%d   I-frames: %s\nKnight: %s" % [
			p_names[p_idx] if p_idx < p_names.size() else "?",
			int(player.get("hp")), int(player.get("MAX_HP")),
			"YES" if bool(player.get("i_frames_active")) else "no",
			k_names[k_idx] if k_idx < k_names.size() else "?"
		]
	)

	death_label.text = "Deaths: %d" % death_count
