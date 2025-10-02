extends Node2D

@export var arc_degrees: float = 75.0
@export var ray_density: float = 2.0
@export var reach: float = 200.0
@export var offset_degrees: float = 0.0
@export_flags_2d_physics var collision_mask := 1
@export var lock_time: float = 1.25

@export var rotating = false
@export var rotation_clockwise = true
@export var rotation_speed := 15.0
@export var speed := 0


@onready var rays_root: Node2D = $Rays
@onready var beams_root: Node2D = $Beams
@onready var fov_polygon: Polygon2D = $FOV
@onready var detect_timer: Timer = $DetectTimer

const EPS := 0.75

var line_color: Color = Color.from_rgba8(255, 255, 255, 150)
var polygon_color: Color = Color.from_rgba8(255, 0, 0, 80)
var debug_color: Color = Color.from_rgba8(255, 255, 0, 150)

var seeing_player := false

func _ready() -> void:
	global_rotation += deg_to_rad(offset_degrees)
	build_fov()
	
	detect_timer.one_shot = true
	detect_timer.wait_time = lock_time
	if !detect_timer.timeout.is_connected(on_detect_timer_timeout):
		detect_timer.timeout.connect(on_detect_timer_timeout)

func _physics_process(delta: float) -> void:
	if rotating:
		update_rotation(delta)
	update_fov()
	update_fov_polygon()

func update_rotation(dt: float) -> void:
	var rotation_direction = 1.0
	if !rotation_clockwise:
		rotation_direction = -1.0
	rotation += deg_to_rad(rotation_speed) * dt * rotation_direction
	
func update_movement(dt: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("go_left"):
		dir.x -= 1.0
		#_moved = true
	if Input.is_action_pressed("go_up"):
		dir.y -= 1.0
		#_moved = true
	if Input.is_action_pressed("go_right"):
		dir.x += 1.0
		#_moved = true
	if Input.is_action_pressed("go_down"):
		dir.y += 1.0
		#_moved = true
	dir = dir.normalized()
	position += dir * speed * dt

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

		# Debug visuals
		var line := Line2D.new()
		line.width = 1
		line.default_color = debug_color
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.ZERO)
		beams_root.add_child(line)

# Updates logic rays & visual beams
func update_fov() -> void:
	var face := global_rotation
	rays_root.global_rotation = face
	beams_root.global_rotation = face
	
	var count := rays_root.get_child_count()
	if beams_root.get_child_count() < count:
		count = beams_root.get_child_count()
	
	var player_hit := false
	for i in count:
		var rc := rays_root.get_child(i) as RayCast2D
		var line := beams_root.get_child(i) as Line2D
		rc.force_raycast_update()

		var end_global := rc.to_global(rc.target_position)
		if rc.is_colliding():
			end_global = rc.get_collision_point()
			
			# Player hit
			var col := rc.get_collider()
			if col is Node && col.is_in_group("player"):
				player_hit = true
			
		var end_local := beams_root.to_local(end_global)

		line.set_point_position(0, Vector2.ZERO)
		line.set_point_position(1, end_local)
		
	update_detection(player_hit)

# Updates timer depending on if the player is seen
func update_detection(seen: bool) -> void:
	var p := get_tree().get_nodes_in_group("player")[0]
	
	if seen:
		if !seeing_player:
			if p and p.has_method("entered_turret_fov"):
				p.call_deferred("entered_turret_fov")
			seeing_player = true	
			detect_timer.stop()
			detect_timer.start()
	else:
		if seeing_player:
			seeing_player = false
			if p and p.has_method("exited_turret_fov"):
				p.call_deferred("exited_turret_fov")
			detect_timer.stop()

func on_detect_timer_timeout() -> void:
	if !seeing_player:
		return
	get_tree().get_nodes_in_group("player")[0].call_deferred("die")

func get_all_walls() -> Array[Rect2]:
	var map := get_tree().get_root().find_child("Map", true, false) as TileMap
	if map == null:
		return []
	
	var walls: Array[Rect2] = []
	var tile_size := map.tile_set.tile_size
	
	for cell in map.get_used_cells(0):  # layer 0 (adapt if needed)
		var local_pos := map.map_to_local(cell)
		var global_pos := map.to_global(local_pos)
		var rect := Rect2(global_pos, tile_size)
		walls.push_back(rect)
	
	return walls

# Returns all vertices in the fov of the turret
func get_seen_vertices() -> PackedVector2Array:
	
	# Get all vertices
	var candidates := PackedVector2Array()
	var walls_root = get_all_walls()
	for wall in walls_root:
		var p := wall["position"] as Vector2
		var s := wall["size"] as Vector2
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

# Returns true if vertex is in fov, false otherwise
func vertex_in_fov(v: Vector2) -> bool:
	if global_position.distance_to(v) > reach:
		return false

	# Compare angle to turret facing (global) + offset
	var facing := global_rotation + deg_to_rad(offset_degrees)
	var to_v := Vector2(v - global_position).angle()
	var delta := float(abs(wrapf(to_v - facing, -PI, PI)))
	return delta <= deg_to_rad(arc_degrees) * 0.5

# Returns true if a ray shot from turret can get to and pass through the vertex v
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
func update_fov_polygon() -> void:
	var face := global_rotation + deg_to_rad(offset_degrees)
	var pts := []

	for child in beams_root.get_children():
		if child is Line2D and child.get_point_count() >= 2:
			var p_local := Vector2(child.get_point_position(1))
			if p_local.length_squared() < 1e-6:
				continue
			var p_world := beams_root.to_global(p_local)
			var ang := wrapf((p_world - global_position).angle() - face, -PI, PI)
			pts.append({ "ang": ang, "p_world": p_world })

	if pts.size() < 2:
		fov_polygon.polygon = PackedVector2Array()
		return

	pts.sort_custom(func(a, b): return a.ang < b.ang)

	var filtered: Array = []
	for e in pts:
		if filtered.is_empty():
			filtered.append(e)
		else:
			var last = filtered[filtered.size() - 1]
			if abs(wrapf(e.ang - last.ang, -PI, PI)) < 0.0005:
				var e_len := (e.p_world - global_position).length_squared() as float
				var l_len := (last.p_world - global_position).length_squared() as float
				if e_len > l_len:
					filtered[filtered.size() - 1] = e
			else:
				filtered.append(e)

	var poly := PackedVector2Array()
	poly.push_back(fov_polygon.to_local(global_position))
	for e in filtered:
		poly.push_back(fov_polygon.to_local(e.p_world))

	fov_polygon.polygon = poly
	fov_polygon.color = polygon_color
