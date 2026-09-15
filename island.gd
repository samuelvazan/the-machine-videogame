class_name Island
extends Node3D

var data: IslandData # The data this particular loaded island represents.
@onready var grid_map: GridMap = $GridMap


func setup(new_data: IslandData) -> void: #Load up the entire island GridMap
	data = new_data # Keep the data so future edits can also modify it.

	grid_map.clear() # Start from an empty generic Island scene.

	for position in data.cells:
		grid_map.set_cell_item(position, data.cells[position]) # Turn saved tile data into the actual GridMap.


func set_cell(position: Vector3i, tile: int) -> void:
	data.set_cell(position, tile) # Change the island's stored state.
	grid_map.set_cell_item(position, tile) # Immediately show the same change on screen.
