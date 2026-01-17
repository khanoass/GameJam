extends Node2D

func _ready():
	if GameState.get_checkpoint_level() == "":
		get_tree().change_scene_to_file("res://Levels/containment_cell.tscn")
	var lvl = GameState.get_checkpoint_level()
	get_tree().change_scene_to_file("res://Levels/level_"+lvl+".tscn")
