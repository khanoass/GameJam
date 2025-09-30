extends Area2D

@export var next_level: String = "" # optional: path to next scene

func _on_body_entered(body):
	if body.is_in_group("player"): # mark your player with group "player"
		if next_level != "":
			get_tree().change_scene_to_file(next_level)
		else:
			get_tree().reload_current_scene() # placeholder if no UI yet
