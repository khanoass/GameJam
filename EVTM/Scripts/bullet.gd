extends Area2D

@export var speed: float = 200
var direction: Vector2 = Vector2.RIGHT

func _process(delta: float) -> void:
	position += direction * speed * delta



func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().get_nodes_in_group("player")[0].call_deferred("die")
	queue_free()
