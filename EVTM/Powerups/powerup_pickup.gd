class_name PowerupPickup
extends Area2D

@export var id: String = ""
@export var powerup: Powerup

@onready var sprite: Sprite2D = $PowerupSprite

const AMPLITUDE := 3.0
const SPEED := 6.0
var start_y: float
var elapsed_time := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if id == "" or powerup == null or GameState.powerup_is_collected(id):
		queue_free()
		return
	
	var tex := load(powerup.texture_path)
	if tex:
		sprite.texture = tex
	start_y = position.y
	
	if not body_entered.is_connected(_on_area_2d_body_entered):
		body_entered.connect(Callable(self, "_on_area_2d_body_entered"))

func _physics_process(delta: float) -> void:
	elapsed_time += delta
	var off := AMPLITUDE * (sin(elapsed_time * SPEED) + 1.0)
	position.y = start_y - off


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if powerup:
		GameState.collect_powerup(id, powerup)

	queue_free()
