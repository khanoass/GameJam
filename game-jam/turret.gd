extends Node2D

@export var arc_degrees: float = 75.0
@export var ray_density: float = 2.0
@export var reach: float = 500.0
@export var offset_degrees: float = 0.0
@export var line_width: float = 4.0
@export var line_color: Color = Color.from_rgba8(255, 255, 255, 150)
@export var polygon_color: Color = Color.from_rgba8(255, 0, 0, 80)
@export var debug_color: Color = Color.from_rgba8(255, 255, 0, 150)
@export_flags_2d_physics var collision_mask := 2
@export var turn_speed_deg := 90.0
@export var moved := true
@export var EPS := 0.75
@export var ANG_EPS := 0.001

@onready var rays_root: Node2D = $Rays
@onready var beams_root: Node2D = $Beams
@onready var display_beams_root: Node2D = $DisplayBeams
@onready var fov_polygon: Polygon2D = $FOV

func _ready() -> void:
	build_fov()
	update_fov()
	update_display()
	update_fov_polygon_from_display()

func _physics_process(dt: float) -> void:
	update_rotation(dt)
	
	if !moved:
		return
	moved = false
	
	update_fov()
	update_display()
	update_fov_polygon_from_display()

# Updates turret movement
func update_rotation(dt: float) -> void:
	var dir := 0.0
	if Input.is_action_pressed("turn_left"):
		dir -= 1.0
		moved = true
	if Input.is_action_pressed("turn_right"):
		dir += 1.0
		moved = true
	rotation += deg_to_rad(turn_speed_deg) * dir * dt

# Builds logic rays & visual beams
func build_fov() -> void:
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
		line.default_color = debug_color
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.ZERO)
		beams_root.add_child(line)

# Updates logic rays & visual beams
func update_fov() -> void:
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

# Left/right FOV limit beams
func add_limit_beams() -> void:
	var facing := global_rotation + deg_to_rad(offset_degrees)
	var half_arc := deg_to_rad(arc_degrees * 0.5)

	for side in [-1, 1]:
		var ang := facing + half_arc * float(side)
		var max_end := global_position + Vector2.RIGHT.rotated(ang) * reach

		var query := PhysicsRayQueryParameters2D.create(global_position, max_end)
		query.collision_mask = collision_mask

		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		var end_global := max_end
		if hit.has("position"):
			end_global = hit.position

		var line := Line2D.new()
		line.width = line_width
		line.default_color = line_color
		line.add_point(display_beams_root.to_local(global_position))
		line.add_point(display_beams_root.to_local(end_global))
		display_beams_root.add_child(line)

# Builds and updates minimal visual beams
func update_display() -> void:
	
	# Cleanup
	for child in display_beams_root.get_children():
		child.queue_free()

	add_limit_beams()

	var seen_vertices := get_seen_vertices()
	var cast_vertices := PackedVector2Array()

	for v in seen_vertices:
		if !vertex_blocked(v):
			cast_vertices.push_back(v)

	# Cast a shadow edge from each vertex out to the arc limit
	for v in cast_vertices:
		var base := v - global_position
		if base.length() < 1e-3:
			continue
		var dir := base / base.length()
		var dist := Vector2(v - global_position).length()

		var from := v + dir * EPS
		var to := from + dir * (reach - dist + EPS)

		var query := PhysicsRayQueryParameters2D.create(from, to)
		query.collision_mask = collision_mask
		query.hit_from_inside = false

		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		var end_global := to
		if hit.has("position"):
			end_global = hit.position

		var line := Line2D.new()
		line.width = line_width
		line.default_color = line_color
		line.add_point(display_beams_root.to_local(v))
		line.add_point(display_beams_root.to_local(end_global))
		display_beams_root.add_child(line)

# Returns all vertices in the fov of the turret
func get_seen_vertices() -> PackedVector2Array:
	
	# Get all vertices
	var candidates := PackedVector2Array()
	for wall in get_tree().get_first_node_in_group("WallsGroup").get_children():
		var rect := wall.get_child(0) as ColorRect
		var p := rect.global_position
		var s := rect.size
		candidates.push_back(p)
		candidates.push_back(Vector2(p.x + s.x, p.y))
		candidates.push_back(Vector2(p.x + s.x, p.y + s.y))
		candidates.push_back(Vector2(p.x, p.y + s.y))
	
	# Check if seen
	var out := PackedVector2Array()
	for v in candidates:
		if vertex_in_fov(v):
			out.push_back(v) 
	
	return out

func vertex_in_fov(v: Vector2) -> bool:
	if global_position.distance_to(v) > reach:
		return false

	# Compare angle to turret facing (global) + offset
	var facing := global_rotation + deg_to_rad(offset_degrees)
	var to_v := Vector2(v - global_position).angle()
	var delta := float(abs(wrapf(to_v - facing, -PI, PI)))
	return delta <= deg_to_rad(arc_degrees) * 0.5

# Returns true if vertex v can be passed through the ray starting from turret
func vertex_blocked(v: Vector2) -> bool:
	var dir := v - global_position
	var dist := dir.length()
	if dist < 1e-3:
		return false
	dir /= dist

	var space := get_world_2d().direct_space_state

	# Before
	var q1 := PhysicsRayQueryParameters2D.create(global_position, v + dir * EPS)
	q1.collision_mask = collision_mask
	q1.hit_from_inside = false

	var hit1 := space.intersect_ray(q1)
	if hit1.has("position"):
		var d1 := global_position.distance_to(hit1.position)
		if d1 + EPS < dist:
			return true

	# After
	var from2 := v + dir * EPS
	var to2   := from2 + dir * EPS
	var q2 := PhysicsRayQueryParameters2D.create(from2, to2)
	q2.collision_mask = collision_mask
	q2.hit_from_inside = true

	var hit2 := space.intersect_ray(q2)
	if hit2.has("position"):
		return true
	return false

# Updates the fov polygon
func update_fov_polygon_from_display() -> void:
	var pts := []

	for child in beams_root.get_children():
		if child is Line2D and child.get_point_count() >= 2:
			var p := Vector2(child.get_point_position(1))
			if p.length_squared() < 1e-6:
				continue
			var ang := p.angle()
			pts.append({ "ang": ang, "p": p })

	if pts.size() < 2:
		fov_polygon.polygon = PackedVector2Array()
		return

	pts.sort_custom(func(a, b): return a.ang < b.ang)

	var ANG_EPS_LOCAL := 0.0005
	var filtered: Array = []
	for e in pts:
		if filtered.is_empty():
			filtered.append(e)
		else:
			var last = filtered[filtered.size() - 1]
			if abs(wrapf(e.ang - last.ang, -PI, PI)) < ANG_EPS_LOCAL:
				# keep the farther endpoint
				if e.p.length_squared() > last.p.length_squared():
					filtered[filtered.size() - 1] = e
			else:
				filtered.append(e)

	var poly := PackedVector2Array()
	poly.push_back(Vector2.ZERO)
	for e in filtered:
		poly.push_back(e.p)

	fov_polygon.polygon = poly
	fov_polygon.color = polygon_color
