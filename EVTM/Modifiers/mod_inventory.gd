extends Control

@onready var grid = $Panel/GridContainer
const INVENTORY_SIZE = 5

func _ready() -> void:
	InventoryBus.add_item.connect(on_add_item)
	
func on_add_item(data: StatusEffect):
	pass
