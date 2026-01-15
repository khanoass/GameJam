extends CanvasLayer

@onready var tex := $TextureRect
@onready var col := $ColorRect
@onready var lbl := $RichTextLabel

func _ready():
	tex.modulate.a = 0
	col.modulate.a = 0
	lbl.modulate.a = 0
	create_tween().tween_property(tex, "modulate:a", 0.8, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(col, "modulate:a", 0.8, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(lbl, "modulate:a", 1.0, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
