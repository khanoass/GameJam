class_name ChargeTimeBoost
extends Powerup

@export var charge_div: float = 2

func apply(player: Node):
	player.charge_time /= charge_div

func remove(player: Node) -> void:
	player.charge_time = player.base_charge_time
