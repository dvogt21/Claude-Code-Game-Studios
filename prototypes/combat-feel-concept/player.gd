# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the parry/dodge timing window learnable in ~3 attempts?
# Date: 2026-05-28
extends CharacterBody2D

enum State { IDLE, DODGING, PARRYING, HIT, DEAD }

const SPEED        := 250.0
const GRAVITY      := 980.0
const DODGE_DUR    := 0.45
const IFRAME_START := 0.08   # I-frames begin 80ms into the roll
const IFRAME_DUR   := 0.22   # I-frames last 220ms
const PARRY_DUR    := 0.35   # Parry stance stays active this long after tap
const HIT_STUN     := 0.35
const MAX_HP       := 3

var state   : State = State.IDLE
var timer   := 0.0
var i_frames_active := false
var hp      := MAX_HP
var dodge_dir := 1.0
var visual  : ColorRect
var shield  : ColorRect

func _ready() -> void:
	var col  := CollisionShape2D.new()
	var cap  := CapsuleShape2D.new()
	cap.radius = 18.0
	cap.height = 56.0
	col.shape  = cap
	add_child(col)

	visual          = ColorRect.new()
	visual.size     = Vector2(36, 72)
	visual.position = Vector2(-18, -72)
	visual.color    = Color(0.2, 0.5, 1.0)   # Blue = idle
	add_child(visual)

	shield          = ColorRect.new()
	shield.size     = Vector2(10, 44)
	shield.position = Vector2(18, -71)   # right edge of player body (faces knight)
	shield.color    = Color(0.15, 0.85, 0.25)
	shield.visible  = false
	add_child(shield)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_tick(delta)
	move_and_slide()

func _tick(delta: float) -> void:
	match state:
		State.IDLE:
			velocity.x = Input.get_axis("move_left", "move_right") * SPEED
			if Input.is_action_just_pressed("dodge"):
				dodge_dir = sign(velocity.x) if velocity.x != 0.0 else 1.0
				_enter(State.DODGING)
			elif Input.is_action_just_pressed("parry"):
				_enter(State.PARRYING)

		State.DODGING:
			timer -= delta
			var elapsed := DODGE_DUR - timer
			i_frames_active = elapsed >= IFRAME_START and elapsed < IFRAME_START + IFRAME_DUR
			# Yellow = I-frames active, faint purple = rolling but not invincible
			visual.color = Color(0.95, 0.85, 0.1) if i_frames_active else Color(0.45, 0.35, 0.85)
			velocity.x   = dodge_dir * SPEED * 2.2
			if timer <= 0.0:
				i_frames_active = false
				_enter(State.IDLE)

		State.PARRYING:
			velocity.x = 0.0
			timer -= delta
			if timer <= 0.0:
				_enter(State.IDLE)

		State.HIT:
			velocity.x = 0.0
			timer -= delta
			if timer <= 0.0:
				_enter(State.IDLE)

		State.DEAD:
			velocity.x = 0.0

func _enter(s: State) -> void:
	state = s
	shield.visible = (s == State.PARRYING)
	match s:
		State.IDLE:
			visual.color = Color(0.2, 0.5, 1.0)   # Blue
		State.DODGING:
			timer = DODGE_DUR
		State.PARRYING:
			timer = PARRY_DUR
			visual.color = Color(0.15, 0.85, 0.25) # Green = in parry stance
		State.HIT:
			timer = HIT_STUN
			visual.color = Color(1.0, 0.2, 0.15)   # Red
		State.DEAD:
			visual.color = Color(0.4, 0.4, 0.45)   # Gray

# Called by armored_knight.gd when an attack lands
func take_hit() -> void:
	if state == State.DEAD or state == State.HIT or i_frames_active:
		return
	hp -= 1
	if hp <= 0:
		_enter(State.DEAD)
	else:
		_enter(State.HIT)

func is_parrying() -> bool:
	return state == State.PARRYING

func is_dead() -> bool:
	return state == State.DEAD

func reset(pos: Vector2) -> void:
	position    = pos
	velocity    = Vector2.ZERO
	hp          = MAX_HP
	i_frames_active = false
	_enter(State.IDLE)
