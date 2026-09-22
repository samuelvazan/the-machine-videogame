# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

# is a script that every single island has. It handles what the island does when it spawns
# (ie., loads contents based on the island's dataID, saves changes when supposed to despawn, etc..)

class_name Island
extends Node3D

const SPHERE_SCENE := preload("res://assets/sphere.glb")

var data_idx: int = -1
var data: IslandData
var island_manager: IslandManager
var architecture: Node


func _ready() -> void:
	if data_idx == -1:
		add_child(SPHERE_SCENE.instantiate())
		return
	data = island_manager.load_island_data(data_idx)
	if data == null or data.architecture == null:
		return
	architecture = data.architecture.instantiate()
	add_child(architecture)
	if data.data.has("darkness"):
		_apply_darkness(architecture, float(data.data["darkness"]))


func pack_architecture() -> PackedScene:
	if architecture == null:
		return null
	_set_owner_recursive(architecture, architecture)
	var packed_scene := PackedScene.new()
	if packed_scene.pack(architecture) != OK:
		return null
	return packed_scene


func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)


func _apply_darkness(node: Node, darkness: float) -> void:
	if node is MeshInstance3D:
		var brightness := 1.0 - clampf(darkness, 0.0, 1.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(brightness, brightness, brightness)
		node.material_override = material
	for child in node.get_children():
		_apply_darkness(child, darkness)
