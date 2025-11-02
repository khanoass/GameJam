extends CanvasLayer

@onready var label: Label = $MarginContainer/PanelContainer/HBoxContainer/Label

func _ready() -> void:
	_update_label(GameState.keypass_count())
	GameState.keypass_count_changed.connect(_update_label)

func _update_label(count: int) -> void:
	label.text = "%d" % count
