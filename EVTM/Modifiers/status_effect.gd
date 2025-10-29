class_name StatusEffect
extends Resource

@export var name: String
@export var description: String
@export var texture_path: String

func apply(player: Node) -> Variant:
	return null

func remove(player: Node, token: Variant) -> void:
	pass
