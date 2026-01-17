extends Node

var collected_keypasses := {}
var active_keypasses := 0
signal keypass_count_changed(new_count: int)

var unlocked_doors := {}

var collected_powerups := {}
var active_powerups: Array[Powerup]
signal powerups_state_changed(new_state: Array[Powerup])

var came_from_lvl := 0

var collected_stars := {}
var stars_count := 0
signal stars_count_changed(new_count: int)

var checkpoint := ""
var need_checkpoint := false

# Came from
func came_from(arrived_at: int) -> int:
	var temp = came_from_lvl
	came_from_lvl = arrived_at
	return temp
	
func collect_star(id: String) -> bool:
	if star_is_collected(id):
		return false
	collected_stars[id] = true
	stars_count += 1
	emit_signal("stars_count_changed", stars_count)
	return true
	
func star_is_collected(id: String) -> bool:
	return collected_stars.has(id)

# Keypasses
func keypass_count() -> int:
	return active_keypasses

func collect_keypass(id: String) -> bool:
	if keypass_is_collected(id):
		return false
	collected_keypasses[id] = true
	active_keypasses += 1
	emit_signal("keypass_count_changed", active_keypasses)
	return true

func keypass_is_collected(id: String) -> bool:
	return collected_keypasses.has(id)

func use_keypass() -> bool:
	if active_keypasses <= 0:
		return false
	active_keypasses -= 1
	return true

# Doors
func mark_door_unlocked(door_id: String) -> void:
	unlocked_doors[door_id] = true

func is_door_unlocked(door_id: String) -> bool:
	return unlocked_doors.get(door_id, false)

# Powerups
func powerups_state() -> Array[Powerup]:
	return active_powerups

func collect_powerup(id: String, powerup: Powerup) -> bool:
	if powerup_is_collected(id) || powerup_is_active(powerup):
		return false
		
	var player := get_tree().get_first_node_in_group("player")
	if !player:
		return false
	
	active_powerups.append(powerup)
	collected_powerups[id] = true
	emit_signal("powerups_state_changed", active_powerups)
	return true

func powerup_is_collected(id: String) -> bool:
	return collected_powerups.has(id)

func powerup_is_active(powerup: Powerup) -> bool:
	return active_powerups.has(powerup)
	
# Checkpoint
func set_checkpoint(s: String):
	checkpoint = s

func set_need_checkpoint():
	need_checkpoint = true

func do_need_checkpoint():
	var n = need_checkpoint
	need_checkpoint = false
	return n

func get_checkpoint_level() -> String:
	if checkpoint == "":
		return ""
	return checkpoint.split(";")[0]

func get_checkpoint_point() -> Vector2:
	if checkpoint == "":
		return Vector2.ZERO
	return Vector2(int(checkpoint.split(";")[1]), int(checkpoint.split(";")[2]))
