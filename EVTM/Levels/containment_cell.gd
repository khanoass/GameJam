extends Node2D

const ID = 0

func _ready():
	GameState.came_from(ID)
