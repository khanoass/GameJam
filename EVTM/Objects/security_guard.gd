
extends CharacterBody2D

@export var speed: float = 100.0
var direction: int = 1  # 1 = rechts, -1 = links
@onready var laser = $Laser
var ray_length: float

func _ready() -> void:
	ray_length = laser.target_position.x

func _physics_process(delta: float) -> void:

	velocity.x = direction * speed
	move_and_slide()
	
	if is_on_wall():  # Prüft, ob gerade eine Wand getroffen wurde
		direction *= -1
		
	# Laser-Richtung aktualisieren
	laser.target_position.x = ray_length * direction
	laser.force_raycast_update()

	# Redraw für Laserlinie
	queue_redraw()


func _draw() -> void:
	var start = Vector2.ZERO
	var end = laser.target_position

	if laser.is_colliding():
		end = laser.get_collision_point() - global_position

	draw_line(start, end, Color.RED, 1)
