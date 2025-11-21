# Boden
extends StaticBody2D

func _ready():
	var m := PhysicsMaterial.new()
	m.bounce = 1.0
	m.friction = 0.0
	m.absorbent = true
	physics_material_override = m
