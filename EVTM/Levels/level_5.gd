extends Node2D

@onready var start = $Start
@onready var end1 = $End1
@onready var end2 = $End2

const ID := 5

func _ready():
	var player := get_tree().get_first_node_in_group("player")
	if !player:
		return false
	player.global_position = getStartPosition(GameState.came_from(ID))

func getStartPosition(c: int):
	if c == 8: return end2.global_position
	if c == 6: return end1.global_position
	return start.global_position
