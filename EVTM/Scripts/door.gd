extends StaticBody2D

@export var locked: bool = false
@export var connected_room: String = ""

@onready var rect = $TextureRect
@onready var collision = $CollisionShape2D

# TODO: Keycard changes locked to false

func _ready() -> void:
	if locked: lock()
	else: unlock()

func lock() -> void:
	rect.texture = load("res://Textures/door_locked.png")
	collision.disabled = false

func unlock() -> void:
	rect.texture = load("res://Textures/door_unlocked.png")
	collision.disabled = true

func _on_area_body_entered(body: Node2D) -> void:
	if locked: return
	print("Level finished")
	if body.is_in_group("player"):
		if connected_room != "":
			get_tree().change_scene_to_file(connected_room)
		else:
			get_tree().reload_current_scene()
