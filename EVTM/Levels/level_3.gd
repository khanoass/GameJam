extends Node2D

const ID := 3

func _ready():
	GameState.came_from(ID)
