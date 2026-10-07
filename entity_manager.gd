# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

# manages ALL THE ENTITIES. This includes the Player, NPCs, Verlet ropes, whatever. It doesn't include minor 
# stuff like grass or particles or whatever. NOTHING ELSE manages the spawning/despawning or creation/deletion
# of NPCs. However, other code functions might call certain functions in entity_manager.gd, but
# entity_manager must maintain a complete overview of the state.

extends Node

# Upon start, it should load all suspended entities load the Player (if he doesn't exist). This is done by spawning a entity.tscn. 
# Entity.tscn is always provided this information:
#  - Name # The name of the entity. Unique.
#  - data_index # entity.tscn is a plain node. It loads itself from a preset (ie., player, rope, ...). Each such preset has an ID.
#  - init_info # .tres, various weird structures depending on preset entity is expected to load, could include health or color or anything else specific for a certain type of entity.
#  - spawn_position # Where the entity is spawned.

# The prior spawning is done via a helper function spawn_entity(name, dataindex, ...)
# Additionally, entity.tscn can say that 'it wants to be suspended until it enters the player's visibility range, or until a timeout is reached.
# When this happens, entity_manager must pack the entire entity.tscn and all its children. It remembers its Name.
# If time is exceeded, it deletes the node entirely with all its history. If it reaches the player's
# visibility range (some constant) it will be unsuspended and let again into the scene tree.

# Importantly, player is just another entity. I think it's a good idea to allow 2+ players to be created

const STORAGE_DIR := "user://entities"
const PLAYER_DATA_INDEX := 0

@export var entity_scene: PackedScene = preload("res://entity.tscn")
@export var starter_player_name := "player"
var loaded_entities: Dictionary = {}
var suspended_entities: Dictionary = {}

func _ready() -> void: # Runs on initialization. Restores saved entities and spawns a player if there isn't one.
	_load_suspended_entities()
	var has_player := false
	for entity in loaded_entities.values():
		if entity.data_index == PLAYER_DATA_INDEX:
			has_player = true
			break
	if not has_player:
		var player_name := starter_player_name
		var suffix := 1
		while loaded_entities.has(player_name) or suspended_entities.has(player_name):
			player_name = starter_player_name + str(suffix)
			suffix += 1
		spawn_entity(player_name, PLAYER_DATA_INDEX)

# API-ish functions. Can technically get called by external scripts. I do NOT recommend it, though. They are meant for entity_manager, if you're using them then there's probably something wrong.
func spawn_entity(Name: String, data_index: int, init_info: Resource = null, spawn_position: Vector3 = Vector3.ZERO) -> Error: # Spawns an entity from entity_scene and tracks it by its unique Name.
	if Name.is_empty() or loaded_entities.has(Name) or suspended_entities.has(Name):
		return ERR_ALREADY_EXISTS
	if entity_scene == null:
		return ERR_INVALID_PARAMETER
	var entity := entity_scene.instantiate()
	if entity == null or not entity.has_method("configure"):
		if entity != null:
			entity.free()
		return ERR_CANT_CREATE
	entity.name = Name
	if entity.name != Name:
		entity.free()
		return ERR_INVALID_PARAMETER
	var error: Error = entity.configure(data_index, init_info, spawn_position)
	if error != OK:
		entity.free()
		return error
	add_child(entity)
	loaded_entities[Name] = entity
	return OK
func suspend_entity(Name: String) -> Error: # Packs a loaded entity into a saved scene and remembers when to restore and deletion timeout.
	if not loaded_entities.has(Name):
		return ERR_DOES_NOT_EXIST
	var entity: Node = loaded_entities[Name]
	entity.spawn_position = entity.get_world_position()
	entity.prepare_for_pack()
	var packed := PackedScene.new()
	var error := packed.pack(entity)
	if error != OK:
		return error
	error = _ensure_storage_dir()
	if error != OK:
		return error
	error = ResourceSaver.save(packed, _entity_path(Name))
	if error != OK:
		return error
	suspended_entities[Name] = {
		"scene": packed,
		"position": entity.spawn_position,
		"range": entity.visibility_range,
		"remaining": entity.suspension_timeout,
	}
	loaded_entities.erase(Name)
	remove_child(entity)
	entity.queue_free()
	return OK
func unsuspend_entity(Name: String) -> Error: # Restores a suspended entity to the scene tree and removes its saved snapshot.
	if not suspended_entities.has(Name):
		return ERR_DOES_NOT_EXIST
	var packed: PackedScene = suspended_entities[Name]["scene"]
	var entity := packed.instantiate()
	if entity == null:
		return ERR_CANT_CREATE
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(_entity_path(Name)))
	if error != OK:
		entity.free()
		return error
	entity.name = Name
	add_child(entity)
	loaded_entities[Name] = entity
	suspended_entities.erase(Name)
	return OK
func delete_entity(Name: String) -> Error: # Deletes an entity, whether it is loaded or suspended.
	if loaded_entities.has(Name):
		var entity: Node = loaded_entities[Name]
		loaded_entities.erase(Name)
		entity.queue_free()
		return OK
	if suspended_entities.has(Name):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(_entity_path(Name)))
		if error != OK:
			return error
		suspended_entities.erase(Name)
		return OK
	return ERR_DOES_NOT_EXIST


# Helper functions for the helper functions. (well, not always, but generally low-level less abstract functions)
func _notification(what: int) -> void: # Suspends loaded entities on close or pause, and restores them on resume.
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		for Name in loaded_entities.keys():
			suspend_entity(Name)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		for Name in suspended_entities.keys():
			unsuspend_entity(Name)
func _load_suspended_entities() -> void: # Loads saved entity scenes from storage back into the scene tree.
	var directory := DirAccess.open(STORAGE_DIR)
	if directory == null:
		return
	for file_name in DirAccess.get_files_at(STORAGE_DIR):
		if not file_name.ends_with(".scn"):
			continue
		var packed := ResourceLoader.load(STORAGE_DIR.path_join(file_name), "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		if packed == null:
			push_error("Could not load suspended entity: " + file_name)
			continue
		var entity := packed.instantiate()
		if entity == null or loaded_entities.has(entity.name):
			push_error("Could not instantiate suspended entity: " + file_name)
			continue
		var Name: String = entity.name
		add_child(entity)
		loaded_entities[Name] = entity
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(STORAGE_DIR.path_join(file_name)))
		if error != OK:
			push_error("Could not remove restored entity snapshot: " + file_name)
func _ensure_storage_dir() -> Error: # Creates the directory used to store suspended entities.
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_DIR))
func _entity_path(Name: String) -> String: # Builds the saved scene path from an entity's Name.
	return STORAGE_DIR.path_join(Name.to_utf8_buffer().hex_encode() + ".scn")

func _process(delta: float) -> void: # Runs every frame. Deletes expired suspended entities or restores visible ones.
	var camera := get_viewport().get_camera_3d()
	for Name in suspended_entities.keys():
		var state: Dictionary = suspended_entities[Name]
		state["remaining"] -= delta
		if state["remaining"] <= 0.0:
			delete_entity(Name)
		elif camera != null and camera.global_position.distance_to(state["position"]) <= state["range"] and camera.is_position_in_frustum(state["position"]):
			unsuspend_entity(Name)
