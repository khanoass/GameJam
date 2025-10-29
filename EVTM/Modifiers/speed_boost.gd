class_name SpeedBoost
extends StatusEffect

@export var speed_mult: float = 1.25

func apply(player: Node) -> Variant:
	if not player.has_variable("speed_mul"):
		push_warning("Player has no 'speed_mul' property")
		return null

	var old_value = player.speed_mul
	player.speed_mul *= speed_mult
	return {"old": old_value, "stat": "speed_mul"}

func remove(player: Node, token: Variant) -> void:
	if token and token.has("old"):
		player.speed_mul = token["old"]
