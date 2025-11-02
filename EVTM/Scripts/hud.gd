extends CanvasLayer

@onready var keyLabel: Label = $KeypassContainer/PanelContainer/HBoxContainer/Label
@onready var powerupsVBox: VBoxContainer = $PowerupsContainer/PanelContainer/VBoxContainer
@onready var powerupsContainer: MarginContainer = $PowerupsContainer

func _ready() -> void:
	update_keypass_label(GameState.keypass_count())
	GameState.keypass_count_changed.connect(update_keypass_label)
	update_powerups(GameState.powerups_state())
	GameState.powerups_state_changed.connect(update_powerups)

func update_keypass_label(count: int) -> void:
	keyLabel.text = "%d" % count

func update_powerups(powerups: Array[Powerup]) -> void:
	for child in powerupsVBox.get_children():
		child.queue_free()
	
	if powerups.size() <= 0:
		powerupsContainer.visible = false
		return

	for p in powerups:
		powerupsVBox.add_child(make_powerup_row(p))

func make_powerup_row(p: Powerup) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(0, 24)

	# Icon
	var icon := TextureRect.new()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(20, 20)

	var tex := load(p.texture_path) as Texture2D
	if tex:
		icon.texture = tex

	# Name
	var name_label := Label.new()
	name_label.text = p.name
	name_label.tooltip_text = p.description
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var spacer := Control.new()
	spacer.custom_minimum_size.x = 4

	row.add_child(icon)
	row.add_child(name_label)
	row.add_child(spacer)
	return row
