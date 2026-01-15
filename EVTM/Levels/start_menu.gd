extends Node2D

@onready var startb := $Start
@onready var quitb := $Quit

func _ready():
	startb.pressed.connect(start)
	quitb.pressed.connect(quit)

func start():
	get_tree().change_scene_to_file("res://Levels/containment_cell.tscn")

func quit():
	get_tree().quit(0)
