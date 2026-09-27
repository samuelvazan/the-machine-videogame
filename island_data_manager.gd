class_name IslandDataManager
extends RefCounted

const DEFAULT_CONTENTS := preload("res://island_contents.tscn")

var repository := IslandDataRepository.new()
var loaded_data: Dictionary = {}
var next_data_idx := 0


func create_island_data() -> int:
	while repository.exists(next_data_idx):
		next_data_idx += 1
	var data := IslandData.new()
	data.architecture = DEFAULT_CONTENTS
	var data_idx := next_data_idx
	var error := repository.create(data_idx, data)
	if error != OK:
		push_error("Could not create island data %d: %s" % [data_idx, error_string(error)])
		return -1
	loaded_data[data_idx] = data
	next_data_idx += 1
	return data_idx
func load_island_data(data_idx: int) -> IslandData:
	if loaded_data.has(data_idx):
		return loaded_data[data_idx]
	var data := repository.load(data_idx)
	if data != null:
		loaded_data[data_idx] = data
	return data
func save_island_data(data_idx: int, data: IslandData) -> Error:
	var error := repository.save(data_idx, data)
	if error == OK:
		loaded_data[data_idx] = data
	return error
func delete_island_data(data_idx: int) -> Error:
	var error := repository.delete(data_idx)
	if error == OK:
		loaded_data.erase(data_idx)
	return error
func exists(data_idx: int) -> bool:
	return repository.exists(data_idx)
func save_graph(nodes: Array, next_node_id: int) -> Error:
	return repository.save_graph(nodes, next_node_id)
func load_graph() -> ConfigFile:
	return repository.load_graph()
