class_name MoonGravity
extends Powerup

@export var gravity_div: float = 3

func apply(player: Node):
	player.gravity /= gravity_div

func remove(player: Node) -> void:
	player.gravity = player.base_gravity
