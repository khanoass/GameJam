extends CharacterBody2D

# Physische Gegebenheiten
@export var gravity: float = 1200           # Erdanziehungskraft
@export var gravity_vector: Vector2 = Vector2(0, gravity) # ... als Vektor
@export var dash_decay := 2.0                # Luftwiderstand bzw. Geschwindigkeitsabfall pro Sekunde

# Spielereigenschaften
@export var charge_time: float = 0.8         # Sekunden bis zur Maximal-Ladung
@export var min_jump_speed: float = -300.0   # kleine Sprunghöhe (negativ = nach oben)
@export var max_jump_speed: float = -600.0   # maximale Sprunghöhe (stärker negativ)

# ... Annahme, dass im ersten Frame der Spieler noch in der Luft ist und runterfällt
var _charging: bool = false
var _dashing: bool = true
var _touching: bool = false
var _charge_elapsed: float = 0.0

# UI Elemente für den Spieler initialisieren
@export var ring_path: String = "ChargeRing"   # zeigt auf dein Player/ChargeRing
var _ring: Node2D

func _ready() -> void:
	_ring = get_node_or_null(ring_path)
	if _ring:
		_ring.visible = true
		if _ring.has_method("set_value"):
			_ring.call("set_value", 0.0)
		
func _show_ring():
	if _ring:
		_ring.visible = true

func _hide_ring():
	if _ring:
		if _ring.has_method("set_value"):
			_ring.call("set_value", 0.0)

func _update_ring(t: float):
	if _ring and _ring.has_method("set_value"):
		_ring.call("set_value", t)  # t = 0..1

func _physics_process(delta: float) -> void:
	if _dashing:
		_dash_step(delta)
	elif _touching: # kann einen Sprung nur aufladen wenn der Player sich nicht bewegt
		_check_for_charge(delta)
	else:
		pass
	
func _apply_dash() -> void:
	var t: float = _charge_elapsed / max(charge_time, 0.0001)  # 0..1
	var jump_dir: Vector2 = (global_position - get_child(3).global_position).normalized()
	var eased := t * t  # weiche Kurve; ersetze durch t für linear
	var jump_speed: float = lerp(min_jump_speed, max_jump_speed, clamp(eased, 0.0, 1.0))
	velocity = jump_dir * jump_speed
	_charging = false
	_dashing = true
	
func _check_for_charge(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_charging = true
		_charge_elapsed = 0.0
		_show_ring()

	# Aufladen solange Space gehalten wird
	if _charging and Input.is_action_pressed("jump"):
		_charge_elapsed = min(_charge_elapsed + delta, charge_time)
		var t: float = _charge_elapsed / max(charge_time, 0.0001)
		_update_ring(t)

	# Bei Release: Sprung auslösen
	if _charging and Input.is_action_just_released("jump"):
		_apply_dash()
		_charging = false
		_hide_ring()
	
	
func _dash_step(delta: float) -> void:
	var motion := velocity * delta
	var collision := move_and_collide(motion)
	
	if collision:
		var collider := collision.get_collider()
		_dashing = false
		_touching = true
		velocity = Vector2.ZERO
		
		if collider and collider.is_in_group("StickyWall"):
			return	
		elif collider and is_on_floor():
			return
		else:
			# Verhalten für nicht definierte Wände = StickyWall
			return
	else:
		# Verhalten bei keiner kollision
		velocity = velocity.move_toward(Vector2.ZERO, dash_decay * delta) + gravity_vector * delta
		if velocity.length() < 1.0:
			_dashing = false
			velocity = Vector2.ZERO
