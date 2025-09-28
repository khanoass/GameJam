extends CharacterBody2D

@export var gravity: float = 1200.0
@export var min_jump_speed: float = -300.0   # kleine Sprunghöhe (negativ = nach oben)
@export var max_jump_speed: float = -900.0   # maximale Sprunghöhe (stärker negativ)
@export var charge_time: float = 0.6         # Sekunden bis zur Maximal-Ladung

var _charging: bool = false
var _charge_elapsed: float = 0.0

func _physics_process(delta: float) -> void:
	# 1) Schwerkraft
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2) Start Charge (nur wenn auf dem Boden)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		_charging = true
		_charge_elapsed = 0.0
		# Optional: horizontale Bewegung stoppen, wenn du Pfeiltasten abschaffen willst
		velocity.x = 0.0

	# 3) Aufladen solange Space gehalten wird
	if _charging and Input.is_action_pressed("jump"):
		_charge_elapsed = min(_charge_elapsed + delta, charge_time)

	# 4) Bei Release: Sprung auslösen
	if _charging and Input.is_action_just_released("jump"):
		var t: float = _charge_elapsed / max(charge_time, 0.0001)  # 0..1
		var jump_dir: Vector2 = (global_position - get_child(3).global_position).normalized()
		var eased := t * t  # weiche Kurve; ersetze durch t für linear
		var jump_speed: float = lerp(min_jump_speed, max_jump_speed, clamp(eased, 0.0, 1.0))
		velocity = jump_dir * jump_speed
		_charging = false

	move_and_slide()
