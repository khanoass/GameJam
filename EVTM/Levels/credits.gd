extends CanvasLayer

@onready var backb := $Back

func _ready():
	backb.pressed.connect(back)

func back():
	get_tree().change_scene_to_file("res://Levels/start_menu.tscn")
