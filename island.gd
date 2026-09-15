class_name Island
extends Node3D

const GROUND_TILE_ID := 0
const TEST_PLATFORM_SIZE := Vector3i(5, 1, 5)
const TEST_PLATFORM_FIRST_CELL := Vector3i(-2, 0, -2)

var data: IslandData # The data this particular loaded island represents.
@onready var grid_map: GridMap = $GridMap


func setup(new_data: IslandData = null) -> void:
	data = new_data # Keep the data so future edits can also modify it.

	grid_map.clear() # Start from an empty generic Island scene.
	_fill_test_platform()

	# The saved GridMap loading is intentionally kept for when island data is
	# used again. For now, every spawned island is the same test platform.
	# _load_cells_from_data()


func _fill_test_platform() -> void:
	# Godot uses Y for height, so this makes a horizontal 5 x 1 x 5 slab.
	var past_last_x := TEST_PLATFORM_FIRST_CELL.x + TEST_PLATFORM_SIZE.x
	var past_last_z := TEST_PLATFORM_FIRST_CELL.z + TEST_PLATFORM_SIZE.z
	for x in range(TEST_PLATFORM_FIRST_CELL.x, past_last_x):
		for z in range(TEST_PLATFORM_FIRST_CELL.z, past_last_z):
			grid_map.set_cell_item(Vector3i(x, 0, z), GROUND_TILE_ID)


func _load_cells_from_data() -> void:
	if data == null:
		return

	for position in data.cells:
		grid_map.set_cell_item(position, data.cells[position]) # Turn saved tile data into the actual GridMap.


func set_cell(position: Vector3i, tile: int) -> void:
	if data != null:
		data.set_cell(position, tile) # Change the island's stored state.
	grid_map.set_cell_item(position, tile) # Immediately show the same change on screen.
