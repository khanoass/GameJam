extends CharacterBody2D

# Powerup variables
var base_speed = 1
var speed = 1
var base_gravity = 1200
@export var gravity: float = 1200
var base_charge_time := 0.8
@export var charge_time := 0.8

@export var player_mass: float = 1.0

var _attached_body: RigidBody2D = null
var _attached_offset: Vector2 = Vector2.ZERO

@export var max_jump_speed: float = -600.0
@export var min_jump_speed: float = -300.0
@export var bounce_coeff := 0.9
@export var dash_decay := 2.0
@export var min_speed_after_bounce := 60.0
@export var slide_keep_ratio := 0.85
@export var slide_decay := 0.0

@export var ring_path: String = "ChargeRing"

@onready var sprite := $AnimatedSprite2D

@onready var PauseMenu = preload("res://Levels/pause_menu.tscn")
@onready var DeadOverlay = preload("res://Levels/dead_overlay.tscn")
var overlayOpacity := 0

var _charging: bool = false
var _dashing: bool = true
var _charge_elapsed: float = 0.0
var _on_ice_this_step := false
var _ice_tangent := Vector2.ZERO
var _ring: Node2D
var _turrets_seeing := 0
var _caught := false
var keycard := 0

var camefrom: int = 0

var dead := false

const EPS := 0.001

enum OBJECT_TYPE {
	PLAYER,
	MOVEABLE,
	INTERACTABLE
}

var object_type: OBJECT_TYPE = OBJECT_TYPE.PLAYER

enum WALL_TYPE {
	Sticky,
	Bouncy,
	Sliding
}

const WALLS := {
	"sticky": WALL_TYPE.Sticky,
	"bouncy": WALL_TYPE.Bouncy,
	"sliding": WALL_TYPE.Sliding
}

# Called by camera when hitting the player
func die():
	dead = true
	_caught = true
	_ring.visible = false
	update_spot_color()
	if is_queued_for_deletion():
		return
	
	# Spawn gas at top of the screen
	var smoke = preload("res://Objects/smoke_effect.tscn").instantiate()
	get_tree().current_scene.add_child(smoke)
	
	var viewport_size = get_viewport_rect().size
	var camera = get_viewport().get_camera_2d().global_position
	var top_center = camera - Vector2(0, viewport_size.y / 2)
	smoke.global_position = top_center + Vector2(viewport_size.x / 2, 0)
	
	var deado := DeadOverlay.instantiate()
	add_child(deado)
	
	await get_tree().create_timer(4).timeout
	
	# Back to spawn point
	get_tree().change_scene_to_file("res://Levels/containment_cell.tscn")

func entered_turret_fov():
	_turrets_seeing += 1
	update_spot_color()

func exited_turret_fov():
	_turrets_seeing = max(0, _turrets_seeing - 1)
	update_spot_color()

func update_spot_color():
	if !_caught:
		sprite.modulate = Color(1,1,1,1)
	if _turrets_seeing > 0 || dead:
		sprite.modulate = Color(1, 0, 0, 1)

func _enter_tree() -> void:
	add_to_group("player", true)

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("player")
	_ring = get_node_or_null(ring_path)
	if _ring:
		_ring.visible = true
		if _ring.has_method("set_value"):
			_ring.call("set_value", 0.0)
	# Powerups
	update_powerups(GameState.powerups_state())
	GameState.powerups_state_changed.connect(update_powerups)

func update_powerups(powerups: Array[Powerup]):
	for p in powerups:
		p.apply(self)
		
func _process(delta: float) -> void:
	if Input.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		get_tree().paused = false
	else:
		get_tree().paused = true
		var menu := PauseMenu.instantiate()
		add_child(menu)

func _physics_process(delta: float):
	if _attached_body != null:
		_update_attached_state(delta)
		check_for_charge(delta)
		return
		
	if dead:
		return

	if _dashing:
		dash_step(delta)
		return

	check_for_charge(delta)
	
func _update_attached_state(delta: float) -> void:
	if _attached_body == null or not is_instance_valid(_attached_body):
		_attached_body = null
		return
	global_position = _attached_body.global_position + _attached_offset
	
func _detach_from_body() -> void:
	_attached_body = null
	_attached_offset = Vector2.ZERO
		
func show_ring():
	if _ring:
		_ring.visible = true

func hide_ring():
	if _ring:
		if _ring.has_method("set_value"):
			_ring.call("set_value", 0.0)

func update_ring(t: float):
	if _ring and _ring.has_method("set_value"):
		_ring.call("set_value", t)  # t = 0..1
	
func apply_dash():
	var t: float = _charge_elapsed / max(charge_time, 0.0001)  # 0..1
	var jump_dir: Vector2 = (global_position - get_child(3).global_position).normalized()
	var eased := t * t  # weiche Kurve; ersetze durch t für linear
	
	var min = min_jump_speed * speed
	var max = max_jump_speed * speed
	var jump_speed: float = lerp(min, max, clamp(eased, 0.0, 1.0))
	
	if _attached_body != null:
		_detach_from_body()
		
	velocity = jump_dir * jump_speed
	_charging = false
	_dashing = true
	
func check_for_charge(delta: float):
	if Input.is_action_just_pressed("jump"):
		_charging = true
		_charge_elapsed = 0.0
		show_ring()

	# Aufladen solange Space gehalten wird
	if _charging and Input.is_action_pressed("jump"):
		_charge_elapsed = min(_charge_elapsed + delta, charge_time)
		var t: float = _charge_elapsed / max(charge_time, 0.0001)
		update_ring(t)

	# Bei Release: Sprung auslösen
	if _charging and Input.is_action_just_released("jump"):
		apply_dash()
		_charging = false
		hide_ring()
	
func dash_step(delta: float):
	velocity += Vector2(0, gravity) * delta

	var remaining := velocity * delta
	var max_iters := 12
	var max_step := 8.0

	_on_ice_this_step = false
	_ice_tangent = Vector2.ZERO

	while max_iters > 0 and remaining.length() > EPS:
		var step := remaining
		if step.length() > max_step:
			step = step.normalized() * max_step

		var collision: KinematicCollision2D = move_and_collide(step, false, 0.02, true)
		
		if collision == null:
			remaining -= step
			max_iters -= 1
			continue
			
		var collider := collision.get_collider()
			
		if collider is RigidBody2D:
			_handle_rigidbody_collision(collision, velocity)
			if _attached_body != null:
				remaining = Vector2.ZERO
				break
				
			var r_rb := collision.get_remainder()
			remaining = r_rb
			max_iters -= 1
			continue
		
		var n := collision.get_normal().normalized()
		var r := collision.get_remainder()
		var is_recovery := r.is_zero_approx() and collision.get_travel().is_zero_approx()

		if is_recovery:
			global_position += n * 0.5
			remaining = Vector2.ZERO
			break

		var type := get_tile_type(collision, n)

		var cont := update_wall_collision(type, n, r)

		if cont.length() < EPS:
			remaining = Vector2.ZERO
			break

		remaining = cont
		max_iters -= 1

	if _on_ice_this_step and _ice_tangent != Vector2.ZERO:
		var t := _ice_tangent.normalized()
		var v_t := velocity.project(t)
		var v_n := velocity - v_t
		v_t = v_t.move_toward(Vector2.ZERO, slide_decay * delta)
		v_n = v_n.move_toward(Vector2.ZERO, dash_decay * delta)
		velocity = v_t + v_n
	else:
		velocity = velocity.move_toward(Vector2.ZERO, dash_decay * delta)

	if velocity.length() < 1.0:
		_dashing = false
		velocity = Vector2.ZERO

func get_tile_type(collision: KinematicCollision2D, normal: Vector2) -> WALL_TYPE:
	var tmap := collision.get_collider() as TileMap
	var def := WALL_TYPE.Sticky
	if tmap == null:
		return def

	var layer := 0
	var probe := collision.get_position() - normal
	var coords := tmap.local_to_map(tmap.to_local(probe))

	var data := tmap.get_cell_tile_data(layer, coords)
	if data == null:
		return def

	var tt = data.get_custom_data("wall_type")
	if tt is StringName:
		tt = String(tt)
	if WALLS.has(tt):
		return WALLS[tt]

	return def

func update_wall_collision(type: WALL_TYPE, normal, remainder) -> Vector2:
	var wall_dispatch := {
		WALL_TYPE.Sticky: Callable(self, "update_sticky"),
		WALL_TYPE.Bouncy: Callable(self, "update_bouncy").bind(normal, remainder),
		WALL_TYPE.Sliding: Callable(self, "update_sliding").bind(normal, remainder),
	}
	return wall_dispatch.get(type).call()

func update_sticky() -> Vector2:
	_on_ice_this_step = false
	velocity = Vector2.ZERO
	_dashing = false
	return Vector2.ZERO

func update_bouncy(n, r) -> Vector2:
	_on_ice_this_step = false
	velocity = velocity.bounce(n) * bounce_coeff
	if velocity.length() >= min_speed_after_bounce:
		return Vector2.ZERO
	
	_dashing = false
	velocity = Vector2.ZERO
	return r.bounce(n)
	
func update_sliding(n: Vector2, r: Vector2) -> Vector2:
	var is_floor := bool(n.y < 0.0 and abs(n.y) >= abs(n.x))
	var is_wall := bool(abs(n.x) > abs(n.y))
	var is_ceiling := n.y > 0.6

	if is_floor:
		var tangent := n.orthogonal().normalized()
		var v_n := velocity.project(n)
		var v_t := velocity - v_n
		if v_t.dot(tangent) < 0.0:
			tangent = -tangent

		var t_speed := v_t.length()

		var min_slide := min_speed_after_bounce * 0.25
		if t_speed < min_slide and v_t.length() > 0.001:
			t_speed = min_slide

		velocity = tangent * t_speed

		var r_tangent := r - r.project(n)
		if r_tangent.is_zero_approx():
			r_tangent = tangent * 0.001

		_on_ice_this_step = true
		_ice_tangent = tangent
		return r_tangent
		
	if is_wall:
		var tangent := n.orthogonal().normalized()
		if velocity.dot(tangent) < 0.0:
			tangent = -tangent
		velocity = velocity.slide(n)
		var rr := r.slide(n)
		if rr.is_zero_approx():
			rr = tangent * 0.001 + n * 0.001
		_on_ice_this_step = true
		_ice_tangent = tangent
		return rr

	if is_ceiling:
		if velocity.y < 0.0:
			velocity.y = 0.0
		return r - r.project(n)

	var fallback_tangent := n.orthogonal().normalized()
	velocity = velocity.project(fallback_tangent)
	return r - r.project(n)

func get_current_velocity() -> Vector2:
	return velocity

func _handle_rigidbody_collision(collision: KinematicCollision2D, prev_velocity: Vector2) -> void:
	var body := collision.get_collider() as RigidBody2D
	if body == null:
		return

	var m1: float = player_mass
	var m2: float = body.mass
	var denom := m1 + m2
	if denom <= 0.0:
		return

	var v1: Vector2 = prev_velocity
	var v2: Vector2 = body.linear_velocity

	# Voll inelastischer Stoß: Impuls geht in gemeinsame Geschwindigkeit
	var v_common: Vector2 = (m1 * v1 + m2 * v2) / denom
	body.linear_velocity = v_common

	# Spieler wird an der Box "festgepinnt" – egal ob oben drauf oder seitlich
	_attached_body = body
	_attached_offset = global_position - body.global_position

	# Eigene Bewegung stoppen, Dash beenden
	velocity = Vector2.ZERO
	_dashing = false
