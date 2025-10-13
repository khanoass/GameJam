extends RigidBody2D

func _ready() -> void:
	# Kollisionsevents erlauben
	contact_monitor = true
	max_contacts_reported = 8

	# Optional: nicht einschlafen
	can_sleep = false

	# Richtig: CCD in 2D über 'continuous_cd' (Enum, kein Bool!)
	# Mögliche Werte:
	# RigidBody2D.CCD_MODE_DISABLED
	# RigidBody2D.CCD_MODE_CAST_RAY
	# RigidBody2D.CCD_MODE_CAST_SHAPE
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

	# (optional) simples Signal weiter nutzen
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("Player berührt die Box")

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var n := state.get_contact_count()
	if n <= 0:
		return
	for i in n:
		var other := state.get_contact_collider_object(i)
		if other and other.is_in_group("player"):
			print("Kontakt im Physikstate: Player ↔ Box")
			var v := Vector2.ZERO
			if other.has_method("get_current_velocity"):
				# Wenn dein Player CharacterBody2D ist
				v = other.get_current_velocity()
			elif "velocity" in other:
				v = other.velocity
			state.linear_velocity = Vector2(v.x, 0.0)
			break
