extends Area2D

# lvl ; x ; y
@export var checkpoint: String = "5;-16;-136"
@onready var sprite: AnimatedSprite2D = $Sprite2D

func _ready():
	sprite.play("idle")

func _on_body_entered(body):
	if !body.is_in_group("player"):
		return
	var lvl = checkpoint.split(";")[0]
	var x = checkpoint.split(";")[1]
	var y = checkpoint.split(";")[2]
	print("Check point at level "+lvl+" at ("+x+" ; "+y+")")
	GameState.set_checkpoint(checkpoint)
	sprite.play("pressed")
