extends Node2D

@export var arc_degrees: float = 100.0
@export var ray_density: float = 1.0
@export var reach: float = 500.0
@export var offset_degrees: float = 0.0
@export var line_width: float = 1.0
@export_flags_2d_physics var collision_mask := 1 << 1
@export var turn_speed_deg := 90.0
@export var moved := true

@onready var rays_root: Node2D = $Rays
@onready var beams_root: Node2D = $Beams

# TODO: func build/update collision polygon

func _ready() -> void:
	build_rays()

func _physics_process(dt: float) -> void:
	update_rotation(dt)
	update_rays()

func update_rotation(dt: float) -> void:
	var dir := 0.0
	if Input.is_action_pressed("turn_left"):
		dir -= 1.0
		moved = true
	if Input.is_action_pressed("turn_right"):
		dir += 1.0
		moved = true
	rotation += deg_to_rad(turn_speed_deg) * dir * dt

func build_rays() -> void:
	for c in rays_root.get_children(): c.queue_free()
	for c in beams_root.get_children(): c.queue_free()

	var arc := deg_to_rad(arc_degrees)
	var start := -arc * 0.5
	var ray_count = int(ray_density * arc_degrees)
	var step := 0.0
	if ray_count > 1:
		step = arc / float(ray_count - 1)

	for i in ray_count:
		var angle := float(start + step * i)

		# Logic
		var rc := RayCast2D.new()
		rc.collision_mask = collision_mask
		rc.target_position = Vector2.RIGHT.rotated(angle) * reach
		rc.enabled = true
		rays_root.add_child(rc)

		# Visual
		var line := Line2D.new()
		line.width = line_width
		line.default_color = Color.YELLOW
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.ZERO)
		beams_root.add_child(line)

func update_rays() -> void:
	if !moved:
		return
		
	rays_root.rotation = deg_to_rad(offset_degrees)
	beams_root.rotation = deg_to_rad(offset_degrees)
	
	var count := rays_root.get_child_count()
	if beams_root.get_child_count() < count:
		count = beams_root.get_child_count()
		
	for i in count:
		var rc := rays_root.get_child(i) as RayCast2D
		var line := beams_root.get_child(i) as Line2D
		rc.force_raycast_update()

		var end_global := rc.to_global(rc.target_position)
		if rc.is_colliding():
			end_global = rc.get_collision_point()
		var end_local := beams_root.to_local(end_global)

		line.set_point_position(0, Vector2.ZERO)
		line.set_point_position(1, end_local)
		moved = false
