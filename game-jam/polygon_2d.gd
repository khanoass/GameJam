extends Polygon2D

@export var radius: float = 20.0

@onready var printed: bool = false

func _physics_process(delta: float) -> void:
	# position from the player and the mouse
	var player = get_parent()
	var player_pos = player.global_position
	var mouse_pos = get_global_mouse_position()
	
	# compute the difference between the two and where on that vector the arrow is
	var offset = (player_pos - mouse_pos).normalized()
	
	# updated the position and rotation of the arrow
	global_position = player_pos - (offset * radius)
	rotation = offset.angle() - PI / 2
