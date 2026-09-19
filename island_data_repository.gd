class_name IslandDataRepository
extends RefCounted

const BUILT_IN_DATA_DIRECTORY := "res://data/islands"
const USER_DATA_DIRECTORY := "user://islands"


func create(data_idx: int, data: IslandData) -> Error:
	if data_idx < 0 or data == null:
		return ERR_INVALID_PARAMETER
	if exists(data_idx):
		return ERR_ALREADY_EXISTS
	return save(data_idx, data)


func load(data_idx: int) -> IslandData:
	var user_path := _user_data_path(data_idx)
	if ResourceLoader.exists(user_path):
		return ResourceLoader.load(user_path) as IslandData
	var built_in_path := _built_in_data_path(data_idx)
	if ResourceLoader.exists(built_in_path):
		return ResourceLoader.load(built_in_path) as IslandData
	return null


func save(data_idx: int, data: IslandData) -> Error:
	if data_idx < 0 or data == null:
		return ERR_INVALID_PARAMETER
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(USER_DATA_DIRECTORY))
	if error != OK:
		return error
	return ResourceSaver.save(data, _user_data_path(data_idx), ResourceSaver.FLAG_COMPRESS)


func delete(data_idx: int) -> Error:
	var user_path := _user_data_path(data_idx)
	if not FileAccess.file_exists(user_path):
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(user_path))


func exists(data_idx: int) -> bool:
	return ResourceLoader.exists(_user_data_path(data_idx)) or ResourceLoader.exists(_built_in_data_path(data_idx))


func _user_data_path(data_idx: int) -> String:
	return "%s/data_%d.res" % [USER_DATA_DIRECTORY, data_idx]


func _built_in_data_path(data_idx: int) -> String:
	return "%s/data_%d.tres" % [BUILT_IN_DATA_DIRECTORY, data_idx]
