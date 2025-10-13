extends Area2D

@export var next_level: String = ""

func _on_body_entered(body):
	print("Level finished")
	if body.is_in_group("player"):
		if next_level != "":
			get_tree().change_scene_to_file(next_level)
		else:
			get_tree().reload_current_scene()
