# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

# is a script that every single island has. It handles what the island does when it spawns
# (ie., loads contents based on the island's dataID, saves changes when supposed to despawn, etc..)

class_name Island
extends Node3D

const TILE_LIBRARY := preload("res://assets/tilemap/meshlibrary/tilesv1.tres")

var tree_node_name: String
var data_idx: int = -1
var data: IslandData
var island_data_manager: IslandDataManager
var architecture: Node


func _ready() -> void:
	if data_idx < 0 or island_data_manager == null:
		push_error("Island %s was spawned without island data" % tree_node_name)
		return
	data = island_data_manager.load_island_data(data_idx)
	if data == null or data.architecture == null:
		push_error("Island %s has no PackedScene" % tree_node_name)
		return
	architecture = data.architecture.instantiate()
	add_child(architecture)
	var old_bounds := architecture.find_child("EditorBounds", true, false)
	if old_bounds != null:
		old_bounds.get_parent().remove_child(old_bounds)
		old_bounds.queue_free()
	var selection_area := architecture.find_child("SelectionArea", true, false) as Area3D
	if selection_area == null:
		selection_area = Area3D.new()
		selection_area.name = "SelectionArea"
		var collision := CollisionShape3D.new()
		collision.shape = SphereShape3D.new()
		selection_area.add_child(collision)
		architecture.add_child(selection_area)
	selection_area.collision_layer = 2
	selection_area.collision_mask = 0
	if data.data.has("darkness"):
		_apply_darkness(architecture, float(data.data["darkness"]))
	update_grid_map_scale()


func despawn() -> Error:
	if data == null or architecture == null:
		return ERR_INVALID_DATA
	var packed_scene := pack_architecture()
	if packed_scene == null:
		return ERR_CANT_CREATE
	var previous_scene := data.architecture
	data.architecture = packed_scene
	var error := island_data_manager.save_island_data(data_idx, data)
	if error != OK:
		data.architecture = previous_scene
		return error
	queue_free()
	return OK


func set_world_transform(world_position: Vector3, world_rotation: Basis, radius: float) -> void:
	global_transform = Transform3D(world_rotation, world_position)
	scale = Vector3.ONE * radius
	update_grid_map_scale()


func get_grid_map() -> GridMap:
	if architecture == null:
		return null
	return architecture.get_node_or_null("GridMap") as GridMap


func add_grid_map() -> void:
	if architecture == null or get_grid_map() != null:
		return
	var grid_map := GridMap.new()
	grid_map.name = "GridMap"
	grid_map.mesh_library = TILE_LIBRARY
	grid_map.cell_size = Vector3.ONE * 2.0
	grid_map.collision_layer = 4
	grid_map.collision_mask = 0
	architecture.add_child(grid_map)
	update_grid_map_scale()


func remove_grid_map() -> void:
	var grid_map := get_grid_map()
	if grid_map != null:
		architecture.remove_child(grid_map)
		grid_map.queue_free()


func update_grid_map_scale() -> void:
	var grid_map := get_grid_map()
	if grid_map != null:
		grid_map.scale = Vector3.ONE / maxf(scale.x, 0.001)


func set_tile_at(world_position: Vector3, world_normal: Vector3, erase: bool) -> void:
	var grid_map := get_grid_map()
	if grid_map == null:
		return
	var offset := -0.01 if erase else 0.01
	var cell := grid_map.local_to_map(grid_map.to_local(world_position + world_normal * offset))
	grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM if erase else 0)


func pack_architecture() -> PackedScene:
	if architecture == null:
		return null
	_set_owner_recursive(architecture, architecture)
	var packed_scene := PackedScene.new()
	if packed_scene.pack(architecture) != OK:
		return null
	return packed_scene


func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)


func _apply_darkness(node: Node, darkness: float) -> void:
	if node is MeshInstance3D:
		var brightness := 1.0 - clampf(darkness, 0.0, 1.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(brightness, brightness, brightness)
		node.material_override = material
	for child in node.get_children():
		_apply_darkness(child, darkness)
