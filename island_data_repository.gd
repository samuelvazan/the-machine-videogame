# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

# manages the different datas. You can tell it 'create this data chunk' or 'delete this data chunk' or
# 'load this' and it'll do the logic for you.

class_name IslandDataRepository
extends RefCounted

const BUILT_IN_DATA_DIRECTORY := "res://data/islands"
const USER_DATA_DIRECTORY := "user://islands"
const EMPTY_ISLAND_SCENE := preload("res://island_contents.tscn")


func load(data_idx: int) -> PackedScene:
	if data_idx < 0:
		return null
	var user_path := _user_data_path(data_idx)
	if ResourceLoader.exists(user_path):
		return ResourceLoader.load(user_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var built_in_path := _built_in_data_path(data_idx)
	if ResourceLoader.exists(built_in_path):
		return ResourceLoader.load(built_in_path, "PackedScene") as PackedScene
	var contents := EMPTY_ISLAND_SCENE.instantiate()
	var packed_scene := PackedScene.new()
	if packed_scene.pack(contents) != OK:
		contents.free()
		return null
	contents.free()
	if save(data_idx, packed_scene) != OK:
		return null
	return packed_scene


func save(data_idx: int, packed_scene: PackedScene) -> Error:
	if data_idx < 0 or packed_scene == null:
		return ERR_INVALID_PARAMETER
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(USER_DATA_DIRECTORY))
	if error != OK:
		return error
	return ResourceSaver.save(packed_scene, _user_data_path(data_idx))


func delete(data_idx: int) -> Error:
	var user_path := _user_data_path(data_idx)
	if not FileAccess.file_exists(user_path):
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(user_path))


func exists(data_idx: int) -> bool:
	return ResourceLoader.exists(_user_data_path(data_idx)) or ResourceLoader.exists(_built_in_data_path(data_idx))


func _user_data_path(data_idx: int) -> String:
	return "%s/data_%d.tscn" % [USER_DATA_DIRECTORY, data_idx]


func _built_in_data_path(data_idx: int) -> String:
	return "%s/data_%d.tscn" % [BUILT_IN_DATA_DIRECTORY, data_idx]
