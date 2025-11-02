extends StaticBody2D

@export var id: String = ""

const AMPLITUDE = 3
const SPEED = 6
var startY: float
var elapsedTime: float = 0.0

func _ready() -> void:
	# Id must be set & can't already be picked up
	if id == "" || GameState.keypass_is_collected(id):
		queue_free()
		return
	startY = position.y

func _physics_process(delta: float) -> void:
	elapsedTime += delta
	var off = AMPLITUDE * (sin(elapsedTime * SPEED) + 1)
	position.y = startY - off

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.collect_keypass(id)
	queue_free()
