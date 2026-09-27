# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

# is a script that every single island has. It handles what the island does when it spawns
# (ie., loads contents based on the island's dataID, saves changes when supposed to despawn, etc..)

class_name Island
extends Node3D

signal clicked(Name: String)

const TILE_LIBRARY := preload("res://assets/tilemap/meshlibrary/tilesv1.tres")

var tree_node_name: String
var data_idx: int = -1
var island_data_repository: IslandDataRepository
var contents: Node3D
var saved_on_despawn := false


func _ready() -> void:
	var packed_scene := island_data_repository.load(data_idx)
	if packed_scene == null:
		push_error("Could not load island %s" % tree_node_name)
		return
	contents = packed_scene.instantiate() as Node3D
	if contents == null:
		push_error("Island %s does not contain a Node3D root" % tree_node_name)
		return
	add_child(contents)
	var selection_area := contents.get_node_or_null("SelectionArea") as Area3D
	if selection_area != null:
		selection_area.input_event.connect(_on_selection_area_input_event)
	else:
		push_error("Island %s has no SelectionArea" % tree_node_name)


func _exit_tree() -> void:
	if contents != null and not saved_on_despawn:
		var error := despawn()
		if error != OK:
			push_error("Could not save island %s: %s" % [tree_node_name, error_string(error)])


func _on_selection_area_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.is_key_pressed(KEY_T):
			toggle_tilemap()
		else:
			clicked.emit(tree_node_name)


func toggle_tilemap() -> void:
	var tilemap := contents.get_node_or_null("TileMap") as GridMap
	if tilemap != null:
		contents.remove_child(tilemap)
		tilemap.queue_free()
		return
	tilemap = GridMap.new()
	tilemap.name = "TileMap"
	tilemap.mesh_library = TILE_LIBRARY
	tilemap.set_cell_item(Vector3i.ZERO, 0)
	contents.add_child(tilemap)
	tilemap.owner = contents


func despawn() -> Error:
	if contents == null:
		return ERR_CANT_CREATE
	var packed_scene := PackedScene.new()
	var error := packed_scene.pack(contents)
	if error != OK:
		return error
	error = island_data_repository.save(data_idx, packed_scene)
	if error == OK:
		saved_on_despawn = true
	return error
