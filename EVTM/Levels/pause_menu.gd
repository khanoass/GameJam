extends CanvasLayer

@onready var resumeb := $Resume
@onready var quitb := $Quit

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _ready():
	resumeb.pressed.connect(resume)
	quitb.pressed.connect(quit)

func resume():
	get_tree().paused = false
	queue_free()

func quit():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Levels/start_menu.tscn")
