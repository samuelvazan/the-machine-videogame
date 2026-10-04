# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

# manages THE ENTIRE ISLAND HIERARCHY AND MOVEMENT. Nothing else should ever manage these.
# Other scripts can ask island_manager via some abstract api to change something but island_manager must
# continue to have a complete overview of the structure.

class_name IslandManager
extends Node

class TreeNode:
	var Name: String #Name. Unique. This is for a friendlier user-code interface
	var Type: String #Type. Nonunique, changable. Can be 'core' or 'tetrahedron' or 'platform' and such.
	var Parentable: bool #Whether I can instantiate children from this node. Changable
	var DataIndex: int #Every platform has its data. But there's a lot of different data files. This says which one belongs to which platform (node).
	var Radius: float #visibility radius of each platform.
	var RotMatrix: Basis #Rotation matrix
	var ChildType: String #Defines what preset its children use. You CANT instantiate an arbiterary child (well, you can, but shouldn't do that) you must use a preset.
	var filled: bool #If filled=true, then that means we're dealing with a platform. If filled=false, then its just a ring.
	var children: Array[TreeNode] #lists its children indexes.
	var child_positions: Array[Vector3]

	func _init(
		new_name: String,
		new_type: String,
		new_parentable: bool,
		new_data_index: int,
		new_radius: float,
		new_rot_matrix: Basis,
		new_child_type: String = "",
		new_filled: bool = false
	) -> void:
		Name = new_name
		Type = new_type
		Parentable = new_parentable
		DataIndex = new_data_index
		Radius = new_radius
		RotMatrix = new_rot_matrix
		ChildType = new_child_type
		filled = new_filled
		children = []
		child_positions = []

@export var island_scene: PackedScene
@export var root_name := "root"
@export var starter_root_radius := 50.0
@export var starter_root_type: String
@export var starter_preset_name: String
@export var starter_nested_child_index := -1
var presets: Dictionary = IslandPresets.PRESETS.duplicate(true)
var tree: Array[TreeNode] = []
var loaded_chunks: Array[Dictionary] = []
var loaded_islands: Dictionary = {}
var island_data_manager := IslandDataManager.new()
var next_node_id := 0


# API - ish functions. Can get used by other scripts safely. (or should, at least. double check)
func apply_preset(Name: String, preset_name: String) -> Error:
	var node_index := _find_node_index(Name)
	if node_index == -1:
		return ERR_DOES_NOT_EXIST
	var parent := tree[node_index]
	var preset := _find_preset(preset_name)
	if preset.is_empty() or not parent.Parentable or parent.Type != preset["parent_type"]:
		return ERR_INVALID_PARAMETER
	for child in preset["children"]:
		if not child.has("type") or not child.has("radius_scale") or not child.has("offset"):
			return ERR_INVALID_DATA
	var previous_filled := parent.filled
	parent.Parentable = false
	parent.filled = preset.get("filled_with_children", false)
	parent.ChildType = preset_name
	for child in preset["children"]:
		if create_island(
			_next_node_name(),
			child["type"],
			child.get("parentable", false),
			parent.Radius * child["radius_scale"],
			child.get("rotation", Basis.IDENTITY),
			"",
			child.get("filled", true),
			Name,
			child["offset"] * parent.Radius
		) == -1:
			_delete_descendants(parent)
			parent.Parentable = true
			parent.filled = previous_filled
			parent.ChildType = ""
			_save_graph()
			return ERR_CANT_CREATE
	_save_graph()
	return OK
func remove_preset(Name: String) -> Error:
	var node_index := _find_node_index(Name)
	if node_index == -1:
		return ERR_DOES_NOT_EXIST
	var parent := tree[node_index]
	var preset := _find_preset(parent.ChildType)
	if preset.is_empty():
		return ERR_INVALID_PARAMETER
	var error := _delete_descendants(parent)
	if error != OK:
		return error
	parent.Parentable = true
	parent.filled = preset.get("filled_without_children", true)
	parent.ChildType = ""
	_save_graph()
	return OK
func toggle_preset(Name: String) -> Error:
	var node_index := _find_node_index(Name)
	if node_index == -1:
		return ERR_DOES_NOT_EXIST
	var node := tree[node_index]
	if node.ChildType != "":
		return remove_preset(Name)
	for preset_name in presets:
		if presets[preset_name]["parent_type"] == node.Type:
			return apply_preset(Name, preset_name)
	return ERR_INVALID_PARAMETER
func _find_preset(preset_name: String) -> Dictionary:
	return presets.get(preset_name, {})

# Perform BFS
func BFS(Name: String, viewer: Vector3, MaxDist: float) -> void: #Perform BFS over all the nodes and register the ones that are visible.
	loaded_chunks.clear()
	var node_index := _find_node_index(Name)
	if node_index == -1:
		return
	var start_node := tree[node_index]
	var nodeXYZ := Vector3.ZERO
	var nodeRotation := start_node.RotMatrix
	if _render_distance(start_node, nodeXYZ, viewer) < MaxDist:
		loaded_chunks.append(_loaded_chunk(start_node.Name, nodeXYZ, nodeRotation, start_node.DataIndex, start_node.Radius))
	var queue: Array[Dictionary] = [{
		"node": start_node,
		"position": nodeXYZ,
		"rotation": nodeRotation,
	}]
	var queue_index := 0
	while queue_index < queue.size():
		var current := queue[queue_index]
		queue_index += 1
		var node: TreeNode = current["node"]
		var node_position: Vector3 = current["position"]
		var node_rotation: Basis = current["rotation"]
		for child_index in range(node.children.size()):
			var child := node.children[child_index]
			var child_position := node_position + node_rotation * node.child_positions[child_index]
			var child_rotation := node_rotation * child.RotMatrix
			if _render_distance(child, child_position, viewer) < MaxDist:
				loaded_chunks.append(_loaded_chunk(child.Name, child_position, child_rotation, child.DataIndex, child.Radius))
			if _ball_distance(child_position, child.Radius, viewer) < MaxDist:
				queue.append({
					"node": child,
					"position": child_position,
					"rotation": child_rotation,
				})
	_sync_loaded_islands()

# Helper functions for island_manager.gd:
func _find_node_index(Name: String) -> int: # finds the node index based on the Name.
	for node_index in range(tree.size()):
		if tree[node_index].Name == Name:
			return node_index
	return -1
func create_island(Name: String, Type: String, Parentable: bool, Radius: float, RotMatrix: Basis, ChildType: String = "", filled: bool = false, parent_name: String = "", local_position: Vector3 = Vector3.ZERO) -> int:
	if _find_node_index(Name) != -1 or Radius <= 0.0:
		return -1
	var parent: TreeNode = null
	if parent_name != "":
		var parent_index := _find_node_index(parent_name)
		if parent_index == -1:
			return -1
		parent = tree[parent_index]
	var data_idx := island_data_manager.create_island_data()
	if data_idx == -1:
		return -1
	var node := TreeNode.new(Name, Type, Parentable, data_idx, Radius, RotMatrix, ChildType, filled)
	tree.append(node)
	if parent != null:
		parent.children.append(node)
		parent.child_positions.append(local_position)
	_save_graph()
	return data_idx
func delete_island(Name: String) -> Error:
	var node_index := _find_node_index(Name)
	if node_index == -1:
		return ERR_DOES_NOT_EXIST
	var error := _delete_island_node(tree[node_index])
	_save_graph()
	return error
func spawn_island(Name: String, position: Vector3, rotation: Basis, radius: float) -> Error:
	var node_index := _find_node_index(Name)
	if node_index == -1 or island_scene == null:
		return ERR_INVALID_PARAMETER
	if loaded_islands.has(Name):
		return ERR_ALREADY_EXISTS
	var new_island := island_scene.instantiate() as Island
	if new_island == null:
		return ERR_CANT_CREATE
	new_island.name = Name
	new_island.tree_node_name = Name
	new_island.data_idx = tree[node_index].DataIndex
	new_island.island_data_manager = island_data_manager
	add_child(new_island)
	loaded_islands[Name] = new_island
	new_island.set_world_transform(position, rotation, radius)
	return OK
func despawn_island(Name: String) -> Error:
	if not loaded_islands.has(Name):
		return ERR_DOES_NOT_EXIST
	var island := loaded_islands[Name] as Island
	var error := island.despawn()
	if error == OK:
		loaded_islands.erase(Name)
	return error

# The helper functions for helper functions.
func _next_node_name() -> String: # generate a unique node Name. For now: n0, n1, n2, n3, ...
	var generated_name := "n" + str(next_node_id)
	next_node_id += 1
	return generated_name
func _delete_descendants(node: TreeNode) -> Error: # the root node itself isnt included
	for child in node.children.duplicate():
		var error := _delete_island_node(child)
		if error != OK:
			return error
	return OK
func _delete_island_node(node: TreeNode) -> Error:
	var error := _delete_descendants(node)
	if error != OK:
		return error
	error = island_data_manager.delete_island_data(node.DataIndex)
	if error != OK:
		return error
	if loaded_islands.has(node.Name):
		var island := loaded_islands[node.Name] as Island
		island.queue_free()
		loaded_islands.erase(node.Name)
	for parent in tree:
		var child_index := parent.children.find(node)
		if child_index != -1:
			parent.children.remove_at(child_index)
			parent.child_positions.remove_at(child_index)
	tree.erase(node)
	return OK
func _save_graph() -> Error:
	return island_data_manager.save_graph(tree, next_node_id)
func _load_graph() -> Error:
	var config := island_data_manager.load_graph()
	if config == null:
		return ERR_FILE_NOT_FOUND
	var loaded_tree: Array[TreeNode] = []
	var nodes_by_name: Dictionary = {}
	for section in config.get_sections():
		if section == "graph":
			continue
		var data_idx: int = config.get_value(section, "data_idx", -1)
		if not island_data_manager.exists(data_idx):
			return ERR_FILE_NOT_FOUND
		var node := TreeNode.new(
			section,
			config.get_value(section, "type"),
			config.get_value(section, "parentable"),
			data_idx,
			config.get_value(section, "radius"),
			config.get_value(section, "rotation"),
			config.get_value(section, "child_type"),
			config.get_value(section, "filled")
		)
		loaded_tree.append(node)
		nodes_by_name[section] = node
	for node in loaded_tree:
		var child_names: Array = config.get_value(node.Name, "children", [])
		var positions: Array = config.get_value(node.Name, "child_positions", [])
		for child_index in range(child_names.size()):
			var child_name: String = child_names[child_index]
			if not nodes_by_name.has(child_name):
				return ERR_INVALID_DATA
			node.children.append(nodes_by_name[child_name])
			if positions.size() == child_names.size():
				node.child_positions.append(positions[child_index])
			else:
				var preset := _find_preset(node.ChildType)
				if preset.is_empty() or child_index >= preset["children"].size():
					return ERR_INVALID_DATA
				node.child_positions.append(preset["children"][child_index]["offset"] * node.Radius)
	if not nodes_by_name.has(root_name):
		return ERR_INVALID_DATA
	tree = loaded_tree
	next_node_id = config.get_value("graph", "next_node_id", 0)
	return OK
func _ball_distance(position: Vector3, radius: float, viewer: Vector3) -> float:
	return maxf(position.distance_to(viewer) - radius, 0.0)
func _sphere_distance(position: Vector3, radius: float, viewer: Vector3) -> float:
	return absf(position.distance_to(viewer) - radius)
func _render_distance(node: TreeNode, position: Vector3, viewer: Vector3) -> float: # checks if a node is in range for being rendered.
	if node.filled:
		return _ball_distance(position, node.Radius, viewer)
	return _sphere_distance(position, node.Radius, viewer)
func _sync_loaded_islands() -> void: # Actually SPAWN the nodes.
	var requested_islands: Dictionary = {}
	for chunk in loaded_chunks:
		var chunk_name: String = chunk["Name"]
		requested_islands[chunk_name] = true
		if not loaded_islands.has(chunk_name):
			spawn_island(chunk_name, chunk["position"], chunk["rotation"], chunk["Radius"])
		else:
			var island: Island = loaded_islands[chunk_name]
			island.set_world_transform(chunk["position"], chunk["rotation"], chunk["Radius"])
	for chunk_name in loaded_islands.keys():
		if not requested_islands.has(chunk_name):
			despawn_island(chunk_name)
func _loaded_chunk(Name: String, position: Vector3, rotation: Basis, data_index: int, radius: float) -> Dictionary: #compact chunk data into a dict, making it suitable for adding to loaded_chunks[] list
	return {
		"Name": Name,
		"position": position,
		"rotation": rotation,
		"DataIndex": data_index,
		"Radius": radius,
	}

# Runs on intialization.
func _ready() -> void: # This is where I'll create an initial structure for now.
	if _load_graph() == OK:
		return
	if create_island(root_name, starter_root_type, true, starter_root_radius, Basis.IDENTITY, "", true) == -1:
		return
	var root := tree[0]
	if apply_preset(root.Name, starter_preset_name) != OK:
		return
	if starter_nested_child_index >= 0 and root.children.size() > starter_nested_child_index:
		apply_preset(root.children[starter_nested_child_index].Name, starter_preset_name)

@export var rotation_speed_degrees := 0.0 #This is the speed controll. Temporarily disabled, but DO NOT REMOVE IT. Its usefull.

# Runs in a loop, forever, until terminated. It should never get terminated.
func _process(delta: float) -> void:
	if tree.is_empty():
		return
	var rotation_step := Basis(Vector3.BACK, deg_to_rad(rotation_speed_degrees * delta))
	for node in tree:
		node.RotMatrix = (node.RotMatrix * rotation_step).orthonormalized()
	BFS(
		root_name,
		$"../EnvironmentManager/Camera3D".global_position,
		200.0
	)
