
extends CharacterBody2D

@export var vision_range: float = 200.0
@export var speed: float = 100.0
@export var fire_rate: float = 1
@export var can_look_up: bool = false
@export var look_speed: float = 2.0

@onready var bullet_scene = preload("res://Objects/Bullet.tscn")
@onready var laser = $Laser

var direction: int = 1  # 1 = rechts, -1 = links
var fire_timer: float = 0.0
var look_up: bool = false
var tracking_player: bool = false
var player_ref: Node = null

func _physics_process(delta: float) -> void:
	
	var target = Vector2(direction * vision_range, 0)
	velocity.x = direction * speed
	move_and_slide()
	if is_on_wall():
		direction *= -1
	
	# Laser logic
	update_laser(delta)
	check_for_player(delta)
	
	#Redraw für Laserlinie
	queue_redraw()
	
func update_laser(delta: float) -> void:
	if can_look_up:
		if tracking_player and player_ref:
			# Follow player smoothly
			var to_player = (player_ref.global_position - global_position)
			if to_player.length() > vision_range:
				# Player out of range -> stop tracking
				tracking_player = false
				player_ref = null
				return
			
			var target = to_player.normalized() * vision_range
			laser.target_position = laser.target_position.lerp(target, look_speed * delta)
		else:
		# Normal scanning behavior

			var desired_y = -vision_range if look_up else 0.0
			laser.target_position.y = lerp(float(laser.target_position.y), desired_y, look_speed * delta)
			laser.target_position.x = vision_range * direction
			if abs(laser.target_position.y - desired_y) < 5.0:
				look_up = !look_up
	else:
		laser.target_position = Vector2(vision_range * direction, 0.0)
			
	laser.force_raycast_update()

func check_for_player(delta: float) -> void:
	fire_timer -= delta
	if laser.is_colliding():
		var hit = laser.get_collider()
		if hit.is_in_group("bullet"):
			return  # Ignore bullets completely
		var collision_point = laser.get_collision_point()
		var distance = global_position.distance_to(collision_point)
		if distance <= vision_range:
			if hit.is_in_group("player") and fire_timer <= 0:
				player_ref = hit
				tracking_player = true
				fire_bullet()
				fire_timer = fire_rate

func fire_bullet() -> void:
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)

	bullet.global_position = global_position + laser.target_position.normalized() * 20
	bullet.direction = laser.target_position.normalized()
	
func _draw() -> void:
	var start = Vector2.ZERO
	var end = laser.target_position

	if laser.is_colliding():
		var hit = laser.get_collider()
		if hit.is_in_group("bullet"):
			return
		if hit.is_in_group("player"):
			print("Hit the player!")
		end = laser.get_collision_point() - global_position

	draw_line(start, end, Color.RED, 1)
