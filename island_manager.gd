class_name IslandManager
extends Node

@export var island_scene: PackedScene # Assign island.tscn here.
@export var islands: Array[IslandData] = [] # All islands that exist in this world.

var data_by_id: Dictionary = {} # Lets us quickly find IslandData from an ID.
var loaded: Dictionary = {} # Contains only islands that currently exist as Nodes.


func _ready() -> void:
	for data in islands:
		data_by_id[data.id] = data # Build the fast ID lookup once.


func spawn_island(id: int) -> Island:
	if loaded.has(id):
		return loaded[id] # Don't spawn the same island twice.

	if not data_by_id.has(id):
		push_error("Island " + str(id) + " does not exist.")
		return null

	var island := island_scene.instantiate() as Island # Create the generic island.tscn.
	add_child(island) # Add it first so its GridMap is ready.
	island.setup(data_by_id[id]) # Give it the data describing which island it is.

	loaded[id] = island
	return island


func despawn_island(id: int) -> void:
	if not loaded.has(id):
		return

	loaded[id].queue_free() # Remove the visual/physical island, but keep its IslandData.
	loaded.erase(id)


func set_cell(id: int, position: Vector3i, tile: int) -> void:
	if not data_by_id.has(id):
		return

	if loaded.has(id):
		loaded[id].set_cell(position, tile) # Loaded Island handles both data and visuals.
	else:
		data_by_id[id].set_cell(position, tile) # Unloaded Island only needs its data changed.
