extends CharacterBody2D

# Physische Gegebenheiten
@export var gravity: float = 1200           # Anziehungskraft
@export var gravity_vector: Vector2 = Vector2(0, gravity)
@export var dash_decay := 2.0                # Luftwiderstand bzw. Geschwindigkeitsabfall pro Sekunde

# Spielereigenschaften
@export var charge_time: float = 0.6         # Sekunden bis zur Maximal-Ladung
@export var min_jump_speed: float = -300.0   # kleine Sprunghöhe (negativ = nach oben)
@export var max_jump_speed: float = -600.0   # maximale Sprunghöhe (stärker negativ)

var _charging: bool = false
var _dashing: bool = true
var _sticky: bool = false
var _charge_elapsed: float = 0.0

func _physics_process(delta: float) -> void:
	if _dashing:
		_dash_step(delta)
	elif velocity.is_zero_approx():
		_check_for_charge(delta)
	
	# 1) Schwerkraft
	#elif not is_on_floor():
	#	velocity.y += gravity * delta
	# 2) Start Charge (nur wenn auf dem Boden)
	#move_and_slide()
	else:
		velocity = Vector2.ZERO
	
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
		print("charging")
		_charging = true
		_charge_elapsed = 0.0

	# Aufladen solange Space gehalten wird
	if _charging and Input.is_action_pressed("jump"):
		_charge_elapsed = min(_charge_elapsed + delta, charge_time)

	# Bei Release: Sprung auslösen
	if _charging and Input.is_action_just_released("jump"):
		print("released")
		_apply_dash()
	
	
func _dash_step(delta: float) -> void:
	var motion := velocity * delta
	var collision := move_and_collide(motion)
	
	if collision:
		var collider := collision.get_collider()
		_dashing = false
		_sticky = true
		velocity = Vector2.ZERO
		
		print("hit something")
		
		if collider and collider.is_in_group("StickyWall"):
			return	
		elif collider and is_on_floor():
			print("hit the floor")
			return
		else:
			# Verhalten für nicht definierte Wände = StickyWall
			return
	else:
		# Verhalten bei keiner kollision
		velocity = velocity.move_toward(Vector2.ZERO, dash_decay * delta) + gravity_vector * delta
		print(velocity)
		if velocity.length() < 1.0:
			_dashing = false
			velocity = Vector2.ZERO
