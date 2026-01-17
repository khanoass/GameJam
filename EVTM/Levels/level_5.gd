extends Node2D

@onready var start = $Start
@onready var end1 = $End1
@onready var end2 = $End2
@onready var player = preload("res://Objects/player.tscn")

const ID := 5

func _ready():
	var p = player.instantiate() as Node2D
	if !p:
		return
	add_child(p)
	p.global_position = getStartPosition(GameState.do_need_checkpoint(), GameState.came_from(ID))

func getStartPosition(b: bool, c: int) -> Vector2:
	if b: return GameState.get_checkpoint_point()
	if c == 6: return end1.global_position
	if c == 8: return end2.global_position
	return start.global_position
