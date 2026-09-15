class_name IslandManager
extends Node

const FIRST_PLATFORM_LINK_POINT := Vector3(6.0, 0.0, 6.0)
const SECOND_PLATFORM_LINK_POINT := Vector3(-4.0, 0.0, -4.0)
const LINK_ROTATION_DEGREES := 120.0

@export var island_scene: PackedScene # Assign island.tscn here.
@export var islands: Array[IslandData] = [] # All islands that exist in this world.

var data_by_id: Dictionary = {} # Lets us quickly find IslandData from an ID.
var loaded: Dictionary = {} # Contains only islands that currently exist as Nodes.
var link_pivot: Node3D
var linked_platform: Island
var animation_time := 0.0


func _ready() -> void:
	for data in islands:
		data_by_id[data.id] = data # Build the fast ID lookup once.

	spawn_linked_platforms()


func _process(delta: float) -> void:
	if link_pivot == null:
		return

	animation_time += delta
	var angle_degrees := sin(animation_time) * LINK_ROTATION_DEGREES
	link_pivot.rotation.y = deg_to_rad(angle_degrees)


func spawn_linked_platforms() -> void:
	if island_scene == null:
		push_error("IslandManager needs an Island Scene before it can spawn platforms.")
		return

	# Keep using a platform already placed in the scene as the first one. This
	# also makes the manager work in scenes without one by creating it here.
	var first_platform := get_node_or_null("Island") as Island
	if first_platform == null:
		first_platform = _spawn_platform(self, "Island")
	else:
		first_platform.setup()

	# The pivot is the first platform's connection point. The second platform
	# is offset so its own connection point sits exactly on that same pivot.
	link_pivot = Node3D.new()
	link_pivot.name = "LinkPivot"
	first_platform.add_child(link_pivot)
	link_pivot.position = FIRST_PLATFORM_LINK_POINT

	linked_platform = _spawn_platform(link_pivot, "LinkedIsland")
	linked_platform.position = -SECOND_PLATFORM_LINK_POINT


func _spawn_platform(parent: Node, platform_name: String) -> Island:
	var platform := island_scene.instantiate() as Island
	platform.name = platform_name
	parent.add_child(platform) # Add it first so its GridMap is ready.
	platform.setup()
	return platform


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
