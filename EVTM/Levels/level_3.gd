extends Node2D

func _ready():
	var player := get_tree().get_first_node_in_group("player")
	if !player:
		return false
	player.camefrom = 3
