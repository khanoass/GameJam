extends StaticBody2D

@export var id := ""
@export var locked: bool = false
@export var connected_room: String = ""

@onready var rect = $TextureRect
@onready var collision = $CollisionShape2D

func _ready() -> void:
	if id == "":
		queue_free()
		return
	if GameState.is_door_unlocked(id) || !locked:
		unlock()
	else: lock()

func lock() -> void:
	rect.texture = load("res://Textures/door_locked.png")
	collision.disabled = false

func unlock() -> void:
	rect.texture = load("res://Textures/door_unlocked.png")
	collision.disabled = true

func _on_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if locked:
		if GameState.use_keypass():
			unlock()
			GameState.mark_door_unlocked(id)
			get_tree().change_scene_to_file(connected_room)
		return
		
	if connected_room != "":
		get_tree().change_scene_to_file(connected_room)
	else:
		get_tree().reload_current_scene()
