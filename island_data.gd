class_name IslandData
extends Resource

@export var id: int = -1
@export var cells: Dictionary = {} # Vector3i position -> GridMap tile ID


func set_cell(position: Vector3i, tile: int) -> void:
	if tile == -1:
		cells.erase(position) # Empty cells don't need to be stored.
	else:
		cells[position] = tile # Remember which tile belongs at this local position.
