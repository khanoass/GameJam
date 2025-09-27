#func _physics_process(delta):
#horizontal input (-1..1)
#	var input_dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
#	velocity.x = input_dir * speed

	# gravity
#	if not is_on_floor():
#		velocity.y += gravity * delta
#	else:
		# jump if on floor
#		if Input.is_action_just_pressed("ui_accept"):
#			velocity.y = jump_velocity

	# move using CharacterBody2D helper
#	move_and_slide()
extends CharacterBody2D

@export var top_speed := 100.0
@export var jump_velocity := -250.0
@export var gravity := 1000.0

@export var max_charge_time := 1.2 # Sekunden bis Vollaufladung
@export var max_force := 1200.0    # Max. Geschwindigkeit/Impuls je nach Player-Typ
#@export var charge_bar_path: NodePath # optional: Pfad zu einer (Texture)ProgressBar

var _charging := false
var _charge_timer := 0.0
var _charge_bar: ProgressBar

#func _ready() -> void:
#    if player == null:
#        player = get_parent() # falls direktes Child
#    if charge_bar_path != NodePath():
#        _charge_bar = get_node_or_null(charge_bar_path)

func _process(delta: float) -> void:

	# --- Pfeil-Position & Rotation ---
	var dir_arrow: Vector2 = get_child(3).global_position
	var dir: Vector2 = (global_position - dir_arrow.global_position).normalized()

	global_position = player_pos + dir * radius
	rotation = dir.angle()

	# --- Aufladen, solange Space gehalten wird ---
	if _charging:
		_charge_timer = min(_charge_timer + delta, max_charge_time)
		_update_bar()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("charge"):
		_charging = true
		_charge_timer = 0.0
		_update_bar()
	elif event.is_action_released("charge") and _charging:
		_charging = false
		var strength := (_charge_timer / max_charge_time) # 0..1
		_apply_boost(strength)
		_charge_timer = 0.0
		_update_bar()

func _apply_boost(strength: float) -> void:
	# Richtung vom Pfeil zum Spieler erneut bestimmen (robust bei Frame-Unterschieden)
	var mouse_pos = get_viewport().get_mouse_position()
	var dir = (mouse_pos - player.global_position).normalized()
	var force = max_force * strength

	# === Variante A: Player ist CharacterBody2D ===
	if player is CharacterBody2D:
		var cb := player as CharacterBody2D
		cb.velocity = dir * force
		# optional: kurze "Dash"-Unverwundbarkeit/State kannst du im Player selbst handhaben
		return

	# === Variante B: Player ist RigidBody2D ===
	if player is RigidBody2D:
		var rb := player as RigidBody2D
		# In Godot 4 in local/central Impuls auf Weltkoordinaten:
		rb.apply_impulse(dir * force)
		return

	# Fallback: wenn es ein Node2D ist, einfach position versetzen (weniger hübsch/physikalisch)
	if player is Node2D:
		(player as Node2D).global_position += dir * force * 0.01

func _update_bar() -> void:
	if _charge_bar:
		_charge_bar.value = (_charge_timer / max_charge_time) * 100.0
