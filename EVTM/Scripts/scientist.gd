extends CharacterBody2D

@onready var label = $Bubble/Label
@onready var trigger = $TriggerZone
@onready var bubble = $Bubble

var in_range: bool = false
@export var dialogue = ["Ah, a visitor!", "Be careful, the security systems are active.", "Good luck!"]
var line_index: int = 0

@export var bubble_padding: Vector2 = Vector2(1, 1)
@export var max_text_width: float = 50

func _ready() -> void:
	bubble.visible = false
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		in_range = true
		start_dialogue()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		in_range = false
		hide_bubble()
		line_index = 0

func show_bubble(text: String) -> void:
	label.text = text
	await get_tree().process_frame

	# Now Godot correctly calculates the wrapped height
	var text_size: Vector2 = label.get_minimum_size()
	print("corrected text size =", text_size)

	# Resize label
	label.size = text_size

	# Bubble size = text size + padding
	var bubble_size = text_size + bubble_padding * 2
	bubble.size = bubble_size

	# Label padding
	label.position = bubble_padding

	bubble.visible = true


func hide_bubble() -> void:
	bubble.visible = false
	
func start_dialogue() -> void:
	if line_index >= dialogue.size():
		line_index = 0
		hide_bubble()
		return

	show_bubble(dialogue[line_index])
	line_index += 1

	await get_tree().create_timer(2.0).timeout

	if in_range: # still near player
		start_dialogue()
	else:
		hide_bubble()
