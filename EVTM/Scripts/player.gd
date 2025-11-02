extends CharacterBody2D

# Effect multipliers
@export var jump_speed_mul: float = 1.0

@export var gravity: float = 1200
@export var gravity_vector: Vector2 = Vector2(0, gravity)
@export var dash_decay := 2.0
@export var bounce_coeff := 0.9
@export var min_speed_after_bounce := 60.0
@export var slide_keep_ratio := 0.85
@export var slide_decay := 0.0
@export var charge_time: float = 0.8
@export var base_max_jump_speed: float = -600.0
@export var base_min_jump_speed: float = -300.0

@export var ring_path: String = "ChargeRing"

@onready var sprite := $AnimatedSprite2D

var _charging: bool = false
var _dashing: bool = true
var _charge_elapsed: float = 0.0
var _on_ice_this_step := false
var _ice_tangent := Vector2.ZERO
var _ring: Node2D
var _turrets_seeing := 0
var _caught := false
var keycard := 0

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
var _last_wall_type := WALL_TYPE.Sticky

# Called by camera when hitting the player
func die():
	if is_queued_for_deletion():
		return
	_caught = true
		
	# Spawn gas at top of the screen
	var smoke = preload("res://Objects/smoke_effect.tscn").instantiate()
	get_tree().current_scene.add_child(smoke)
	
	var viewport_size = get_viewport_rect().size
	var camera = get_viewport().get_camera_2d().global_position
	var top_center = camera - Vector2(0, viewport_size.y / 2)
	smoke.global_position = top_center + Vector2(viewport_size.x / 2, 0)
	
	await get_tree().create_timer(2.5).timeout
	
	# Back to containment
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
	if _turrets_seeing > 0:
		sprite.modulate = Color(1, 0, 0, 1)

func _enter_tree() -> void:
	add_to_group("player", true)

func _ready():
	add_to_group("player")
	_ring = get_node_or_null(ring_path)
	if _ring:
		_ring.visible = true
		if _ring.has_method("set_value"):
			_ring.call("set_value", 0.0)
			
func _physics_process(delta: float):
	if _dashing:
		dash_step(delta)
		return
	check_for_charge(delta)
		
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
	
	var min = base_min_jump_speed * jump_speed_mul
	var max = base_max_jump_speed * jump_speed_mul
	var jump_speed: float = lerp(min, max, clamp(eased, 0.0, 1.0))
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
	velocity += gravity_vector * delta

	var remaining := velocity * delta
	var max_iters := 8
	var max_step := 16.0

	_on_ice_this_step = false
	_ice_tangent = Vector2.ZERO

	while max_iters > 0 and remaining.length() > EPS:
		var step := remaining
		if step.length() > max_step:
			step = step.normalized() * max_step

		var collision := move_and_collide(step, false, 0.08, true)
		if collision == null:
			remaining -= step
			max_iters -= 1
			continue

		var n := collision.get_normal().normalized()
		var r := collision.get_remainder()
		var is_recovery := r.is_zero_approx() and collision.get_travel().is_zero_approx()

		if is_recovery:
			remaining = r
			max_iters -= 1
			continue

		var type := get_tile_type(collision, n)
		_last_wall_type = type

		var cont := update_wall_collision(type, n, r)

		if (cont - remaining).length() < EPS:
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
	var def := _last_wall_type
	if tmap == null:
		return def

	var layer := 0
	var probe := collision.get_position() - normal * 0.25
	var coords := tmap.local_to_map(tmap.to_local(probe))
	var src := tmap.get_cell_source_id(layer, coords)
	if src == -1:
		return def

	var ac := tmap.get_cell_atlas_coords(layer, coords)
	var alt := tmap.get_cell_alternative_tile(layer, coords)
	var data := tmap.tile_set.get_source(src).get_tile_data(ac, alt) as TileData
	if data == null:
		return def

	var tt = data.get_custom_data("wall_type")
	if tt is String and WALLS.has(tt):
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
	velocity = Vector2.ZERO
	_dashing = false
	return Vector2.ZERO

func update_bouncy(n, r) -> Vector2:
	velocity = velocity.bounce(n) * bounce_coeff
	if velocity.length() >= min_speed_after_bounce:
		return Vector2.ZERO
	
	_dashing = false
	velocity = Vector2.ZERO
	return r.bounce(n)
	
func update_sliding(n: Vector2, r: Vector2) -> Vector2:
	var is_floor := n.y < -0.6
	var is_wall := absf(n.x) > 0.6
	var is_ceiling := n.y > 0.6

	if is_wall:
		velocity.x = 0.0
		var gdir := gravity_vector.normalized()
		if gravity_vector.length() > 0.0:
			gdir = Vector2.DOWN
		return r.project(gdir)

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

	if is_ceiling:
		if velocity.y < 0.0:
			velocity.y = 0.0
		return r - r.project(n)

	var fallback_tangent := n.orthogonal().normalized()
	velocity = velocity.project(fallback_tangent)
	return r - r.project(n)

func get_current_velocity() -> Vector2:
	return velocity
