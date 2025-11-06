extends CharacterBody2D

@onready var speech_bubble = $SpeechBubble
@onready var label = $SpeechBubble/Label
@onready var trigger = $TriggerZone

var in_range: bool = false
@export var dialogue = ["Ah, a visitor!", "Be careful, the security systems are active.", "Good luck!"]
var line_index: int = 0

func _ready() -> void:
	speech_bubble.visible = false
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
	speech_bubble.visible = true

func hide_bubble() -> void:
	speech_bubble.visible = false
	
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
