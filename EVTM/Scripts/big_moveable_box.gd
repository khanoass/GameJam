# Bewegte Box
extends RigidBody2D

@export var speed: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var m := PhysicsMaterial.new()
	m.bounce = 1.0
	m.friction = 0.0
	physics_material_override = m
	gravity_scale = 1.0
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp = 0.0
	linear_velocity = Vector2(speed, 0.0)
