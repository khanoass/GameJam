extends CharacterBody2D

@export var speed := 100.0
@export var jump_velocity := -250.0
@export var gravity := 1000.0

func _physics_process(delta):
	# horizontal input (-1..1)
	var input_dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_dir * speed

	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# jump if on floor
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = jump_velocity

	# move using CharacterBody2D helper
	move_and_slide()
