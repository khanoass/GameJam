extends Node
signal add_item(data)
func request_add_item(data: StatusEffect):
	emit_signal("add_item", data)
