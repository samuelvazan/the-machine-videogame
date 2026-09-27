# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

# manages the different datas. You can tell it 'create this data chunk' or 'delete this data chunk' or
# 'load this' and it'll do the logic for you.

class_name IslandDataRepository
extends RefCounted

const BUILT_IN_DATA_DIRECTORY := "res://data/islands"
const USER_DATA_DIRECTORY := "user://islands"
const GRAPH_PATH := "user://islands/graph.cfg"


func create(data_idx: int, data: IslandData) -> Error:
	if data_idx < 0 or data == null:
		return ERR_INVALID_PARAMETER
	if exists(data_idx):
		return ERR_ALREADY_EXISTS
	return save(data_idx, data)


func load(data_idx: int) -> IslandData:
	var path := _user_data_path(data_idx)
	if not FileAccess.file_exists(path):
		path = _built_in_data_path(data_idx)
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as IslandData


func save(data_idx: int, data: IslandData) -> Error:
	if data_idx < 0 or data == null or data.architecture == null:
		return ERR_INVALID_PARAMETER
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(USER_DATA_DIRECTORY))
	if error != OK:
		return error
	return ResourceSaver.save(data, _user_data_path(data_idx), ResourceSaver.FLAG_COMPRESS)


func delete(data_idx: int) -> Error:
	if data_idx < 0:
		return ERR_INVALID_PARAMETER
	var path := _user_data_path(data_idx)
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func exists(data_idx: int) -> bool:
	return FileAccess.file_exists(_user_data_path(data_idx)) or ResourceLoader.exists(_built_in_data_path(data_idx))


func save_graph(nodes: Array, next_node_id: int) -> Error:
	var config := ConfigFile.new()
	config.set_value("graph", "next_node_id", next_node_id)
	for node in nodes:
		config.set_value(node.Name, "type", node.Type)
		config.set_value(node.Name, "parentable", node.Parentable)
		config.set_value(node.Name, "data_idx", node.DataIndex)
		config.set_value(node.Name, "radius", node.Radius)
		config.set_value(node.Name, "rotation", node.RotMatrix)
		config.set_value(node.Name, "child_type", node.ChildType)
		config.set_value(node.Name, "filled", node.filled)
		var child_names: Array[String] = []
		for child in node.children:
			child_names.append(child.Name)
		config.set_value(node.Name, "children", child_names)
		config.set_value(node.Name, "child_positions", node.child_positions)
	return config.save(GRAPH_PATH)


func load_graph() -> ConfigFile:
	var config := ConfigFile.new()
	if config.load(GRAPH_PATH) != OK:
		return null
	return config


func _user_data_path(data_idx: int) -> String:
	return "%s/data_%d.res" % [USER_DATA_DIRECTORY, data_idx]


func _built_in_data_path(data_idx: int) -> String:
	return "%s/data_%d.tres" % [BUILT_IN_DATA_DIRECTORY, data_idx]
