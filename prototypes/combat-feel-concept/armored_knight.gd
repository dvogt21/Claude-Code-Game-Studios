# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the parry/dodge timing window learnable in ~3 attempts?
# Date: 2026-05-28
extends CharacterBody2D

# ── Tuning ─────────────────────────────────────────────────────────────────
# Adjust these to change how the fight feels without touching logic.
const LIGHT_WINDUP   := 0.55  # seconds of yellow wind-up before light attack
const HEAVY_WINDUP   := 0.95  # seconds of orange wind-up before heavy attack
const ATTACK_ACTIVE  := 0.22  # how long the attack is "live" (the parry window)
const RECOVERY_TIME  := 0.65  # after attack: recovery before next action
const STAGGER_TIME   := 0.85  # after successful parry: how long knight is stunned
const IDLE_WAIT      := 1.1   # pause between actions
const WALK_SPEED     := 110.0
const ATTACK_RANGE   := 95.0  # start attack wind-up within this distance
const HIT_RANGE      := 108.0 # deal damage within this distance during ATTACKING
const GRAVITY        := 980.0
# ───────────────────────────────────────────────────────────────────────────

enum KState { IDLE, WALKING, WINDUP_LIGHT, WINDUP_HEAVY, ATTACKING, RECOVERY, STAGGERED }

var kstate        : KState = KState.IDLE
var timer         := 0.0
var next_heavy    := false   # alternates light/heavy each attack
var hit_applied   := false
var visual        : ColorRect
var sword         : Line2D
var player: CharacterBody2D = null   # set by main.gd after both nodes are in the tree

func _ready() -> void:
	var col  := CollisionShape2D.new()
	var cap  := CapsuleShape2D.new()
	cap.radius = 22.0
	cap.height = 68.0
	col.shape  = cap
	add_child(col)

	visual          = ColorRect.new()
	visual.size     = Vector2(44, 88)
	visual.position = Vector2(-22, -88)
	visual.color    = Color(0.55, 0.55, 0.6)  # Gray = idle
	add_child(visual)

	sword = Line2D.new()
	sword.width           = 8.0
	sword.begin_cap_mode  = Line2D.LINE_CAP_BOX
	sword.end_cap_mode    = Line2D.LINE_CAP_BOX
	sword.default_color   = Color(0.7, 0.7, 0.75)
	sword.add_point(Vector2(-8, -55))   # hilt
	sword.add_point(Vector2(-22, -25))  # tip (idle: hanging at side)
	add_child(sword)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if player == null:
		move_and_slide()
		return
	_tick(delta)
	move_and_slide()

func _tick(delta: float) -> void:
	timer -= delta

	match kstate:
		KState.IDLE:
			velocity.x = 0.0
			if timer <= 0.0:
				_enter(KState.WALKING)

		KState.WALKING:
			var dist: float = abs(position.x - player.position.x)
			if dist <= ATTACK_RANGE:
				_enter(KState.WINDUP_HEAVY if next_heavy else KState.WINDUP_LIGHT)
			else:
				velocity.x = sign(player.position.x - position.x) * WALK_SPEED

		KState.WINDUP_LIGHT, KState.WINDUP_HEAVY:
			velocity.x = 0.0
			if timer <= 0.0:
				hit_applied = false
				_enter(KState.ATTACKING)

		KState.ATTACKING:
			velocity.x = 0.0
			if not hit_applied:
				var dist: float = abs(position.x - player.position.x)
				if dist <= HIT_RANGE:
					if player.call("is_parrying"):
						# ── SUCCESSFUL PARRY ──────────────────────────────
						hit_applied = true
						_enter(KState.STAGGERED)
						return
					else:
						# ── HIT LANDS ─────────────────────────────────────
						hit_applied = true
						player.call("take_hit")
			if timer <= 0.0:
				next_heavy = not next_heavy
				_enter(KState.RECOVERY)

		KState.RECOVERY:
			velocity.x = 0.0
			if timer <= 0.0:
				_enter(KState.IDLE)

		KState.STAGGERED:
			velocity.x = 0.0
			if timer <= 0.0:
				next_heavy = not next_heavy
				_enter(KState.IDLE)

func _enter(s: KState) -> void:
	kstate = s
	_update_sword()
	match s:
		KState.IDLE:
			timer = IDLE_WAIT
			visual.color = Color(0.55, 0.55, 0.6)   # Gray
		KState.WALKING:
			visual.color = Color(0.55, 0.55, 0.6)   # Gray
		KState.WINDUP_LIGHT:
			timer = LIGHT_WINDUP
			visual.color = Color(0.95, 0.85, 0.1)   # Yellow — light incoming
		KState.WINDUP_HEAVY:
			timer = HEAVY_WINDUP
			visual.color = Color(0.95, 0.5, 0.05)   # Orange — heavy incoming
		KState.ATTACKING:
			timer = ATTACK_ACTIVE
			visual.color = Color(1.0, 0.15, 0.1)    # Red — attack is LIVE
		KState.RECOVERY:
			timer = RECOVERY_TIME
			visual.color = Color(0.4, 0.4, 0.45)    # Dark gray
		KState.STAGGERED:
			timer = STAGGER_TIME
			visual.color = Color(1.0, 1.0, 1.0)     # White — staggered!

func _update_sword() -> void:
	match kstate:
		KState.IDLE, KState.WALKING, KState.RECOVERY:
			sword.set_point_position(0, Vector2(-8, -55))
			sword.set_point_position(1, Vector2(-22, -25))
			sword.default_color = Color(0.7, 0.7, 0.75)
		KState.WINDUP_LIGHT:
			# Sword raised and pulled back — telegraphs incoming swing
			sword.set_point_position(0, Vector2(-10, -85))
			sword.set_point_position(1, Vector2(-55, -100))
			sword.default_color = Color(0.95, 0.85, 0.1)   # yellow matches body
		KState.WINDUP_HEAVY:
			# Sword raised higher — bigger, slower swing coming
			sword.set_point_position(0, Vector2(-5, -90))
			sword.set_point_position(1, Vector2(-40, -115))
			sword.default_color = Color(0.95, 0.5, 0.05)   # orange matches body
		KState.ATTACKING:
			# Sword swings out horizontal toward the player — the parry window
			sword.set_point_position(0, Vector2(-22, -55))
			sword.set_point_position(1, Vector2(-105, -55))
			sword.default_color = Color(1.0, 0.15, 0.1)    # red matches body
		KState.STAGGERED:
			sword.set_point_position(0, Vector2(-12, -30))
			sword.set_point_position(1, Vector2(-12, 5))
			sword.default_color = Color(0.55, 0.55, 0.6)

func is_attacking() -> bool:
	return kstate == KState.ATTACKING

func reset(pos: Vector2) -> void:
	position  = pos
	velocity  = Vector2.ZERO
	next_heavy = false
	hit_applied = false
	_enter(KState.IDLE)
