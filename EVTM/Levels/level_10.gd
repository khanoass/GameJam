extends Node2D

@onready var start = $Start
@onready var player = preload("res://Objects/player.tscn")

const ID := 10

func _ready():
	var p = player.instantiate() as Node2D
	if !p:
		return
	add_child(p)
	p.global_position = getStartPosition(GameState.do_need_checkpoint(), GameState.came_from(ID))

func getStartPosition(b: bool, c: int) -> Vector2:
	if b: return GameState.get_checkpoint_point()
	return start.global_position
