class_name SpeedBoost
extends Powerup

@export var speed_mult: float = 2

func apply(player: Node):
	player.speed *= speed_mult

func remove(player: Node) -> void:
	player.speed = player.base_speed
