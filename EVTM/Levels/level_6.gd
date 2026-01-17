extends Node2D

@onready var start = $Start
@onready var end = $End

const ID := 6

func _ready():
	var player := get_tree().get_first_node_in_group("player")
	if !player:
		return false
	player.global_position = getStartPosition(GameState.came_from(ID))

func getStartPosition(c: int):
	if c == 7: return end.global_position
	return start.global_position
