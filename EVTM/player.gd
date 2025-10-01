extends CharacterBody2D

# Physische Gegebenheiten
@export var gravity: float = 1200           # Erdanziehungskraft
@export var gravity_vector: Vector2 = Vector2(0, gravity) # ... als Vektor
@export var dash_decay := 2.0               # Luftwiderstand bzw. Geschwindigkeitsabfall pro Sekunde
@export var bounce_coeff := 0.9             # 0..1 (Energieerhalt beim Abprallen)
@export var min_speed_after_bounce := 60.0
@export var slide_keep_ratio := 0.85        # 0..1 (wie viel Speed beim Sliden erhalten bleibt)

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
	add_to_group("player")
	_ring = get_node_or_null(ring_path)
	if _ring:
		_ring.visible = true
		if _ring.has_method("set_value"):
			_ring.call("set_value", 0.0)
			
func _physics_process(delta: float) -> void:
	if _dashing:
		dash_step(delta)
	elif _touching: # kann einen Sprung nur aufladen wenn der Player sich nicht bewegt
		check_for_charge(delta)
	else:
		pass
		
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
	
func apply_dash() -> void:
	var t: float = _charge_elapsed / max(charge_time, 0.0001)  # 0..1
	var jump_dir: Vector2 = (global_position - get_child(3).global_position).normalized()
	var eased := t * t  # weiche Kurve; ersetze durch t für linear
	var jump_speed: float = lerp(min_jump_speed, max_jump_speed, clamp(eased, 0.0, 1.0))
	velocity = jump_dir * jump_speed
	_charging = false
	_dashing = true
	
func check_for_charge(delta: float) -> void:
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
	
	
func dash_step(delta: float) -> void:
	var motion := velocity * delta
	var collision = move_and_collide(motion)
	
	if !collision:
		velocity = velocity.move_toward(Vector2.ZERO, dash_decay * delta) + gravity_vector * delta
		if velocity.length() < 1.0:
			_dashing = false
			velocity = Vector2.ZERO
		return
		
	var collider := collision.get_collider()
	var n := collision.get_normal().normalized()
	
	print(collider, " is ", collider.get_class())
	
	var tilemap = collider as TileMap
	if tilemap:
		print(tilemap)
		print("Name:", tilemap.name) 
		var coords = tilemap.local_to_map(tilemap.to_local(collision.get_position()))
		print(coords)
		var source_id = tilemap.get_cell_source_id(0, coords)
		if source_id == -1:
			_touching = true
			_dashing = false
			return
		print(source_id)
		var atlas_coords = tilemap.get_cell_atlas_coords(0, coords) # for tiles in atlases
		var alternative = tilemap.get_cell_alternative_tile(0, coords)
		var data = tilemap.tile_set.get_source(source_id).get_tile_data(atlas_coords, alternative)
		if data:
			var tile_type = data.get_custom_data("wall_type")
			print("Tile type:", tile_type)
			print("Custom data:", data)
			match tile_type:
				"sticky":
					print("sticking")
					velocity = Vector2.ZERO
					_touching = true
					_dashing = false
					return
				"bouncy":
					print("bouncing")
					# Verhalten 2) Abprallen: v' = v.bounce(n) * koeff
					velocity = velocity.bounce(n) * bounce_coeff
					if velocity.length() < min_speed_after_bounce:
						# Schutz gegen „steckenbleiben“: entweder stoppen oder Mindest-Tempo
						_dashing = false
						_touching = true
						velocity = Vector2.ZERO
						# Restbewegung im selben Frame optional weglassen → nächste Physik-Iteration macht weiter
					return
				"sliding":
					print("slinding")
					# Verhalten 3) Entlang gleiten: v' = v.slide(n)
					velocity = velocity.slide(n) * slide_keep_ratio
					if velocity.length() < min_speed_after_bounce:
						_dashing = false
						_touching = true
						velocity = Vector2.ZERO
					return
				"default":
					_dashing = false
					_touching = true
