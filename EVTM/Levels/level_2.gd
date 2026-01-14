extends Node2D

@onready var start = $Start
@onready var end = $End

func _ready():
	var player := get_tree().get_first_node_in_group("player")
	if !player:
		return false
	var camefrom = player.camefrom
	var position: Vector2 = getStartPosition(camefrom)
	player.global_position = position
	player.camefrom = 2

func getStartPosition(c: int):
	if c == 4: return end.global_position
	return start.global_position
