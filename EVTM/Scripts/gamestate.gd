extends Node

var collected_keypasses := {}
var active_keypasses := 0

var unlocked_doors := {}

func collect_keypass(id: String):
	if not collected_keypasses.get(id, false):
		collected_keypasses[id] = true
		active_keypasses += 1

func keypass_is_collected(id: String) -> bool:
	return collected_keypasses.get(id, false)

func use_keypass() -> bool:
	if active_keypasses <= 0:
		return false
	active_keypasses -= 1
	return true

func mark_door_unlocked(door_id: String) -> void:
	unlocked_doors[door_id] = true

func is_door_unlocked(door_id: String) -> bool:
	return unlocked_doors.get(door_id, false)
