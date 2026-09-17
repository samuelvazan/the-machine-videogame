# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

class_name IslandManager
extends Node

const TETRAHEDRON_POSITIONS := [
	Vector3(0.0, 0.0, -0.550509375),
	Vector3(0.519025, 0.0, 0.183503125),
	Vector3(-0.2595125, 0.449490625, 0.183503125),
	Vector3(-0.2595125, -0.449490625, 0.183503125),
	Vector3.ZERO,
]
const TETRAHEDRON_RADIUS_SCALE := 0.446875
const CORE_RADIUS_SCALE := 0.1

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

@export var island_scene: PackedScene
var tree: Array[TreeNode] = []
var loaded_chunks: Array[Dictionary] = []
var loaded_islands: Dictionary = {}
var next_node_id := 0


func add_tetrahedron_preset(Name: String) -> void:
	var node_index := _find_node_index(Name)
	var parent := tree[node_index]
	if parent.Type == "tetrahedron" and parent.Parentable:
		parent.Parentable = false
		parent.filled = false
		parent.ChildType = "tetrahedron"
		for _child_index in range(4):
			var child := TreeNode.new(
				_next_node_name(),
				"tetrahedron",
				true,
				-1,
				parent.Radius * TETRAHEDRON_RADIUS_SCALE,
				Basis.IDENTITY,
				"",
				true
			)
			parent.children.append(child)
			tree.append(child)
		var core := TreeNode.new(
			_next_node_name(),
			"core",
			false,
			-1,
			parent.Radius * CORE_RADIUS_SCALE,
			Basis.IDENTITY,
			"",
			true
		)
		parent.children.append(core)
		tree.append(core)
func delete_tetrahedron_preset(Name: String) -> void:
	var node_index := _find_node_index(Name)
	var parent := tree[node_index]
	if parent.ChildType == "tetrahedron":
		_delete_descendants(parent)
		parent.Parentable = true
		parent.ChildType = ""


func BFS(Name: String, viewer: Vector3, MaxDist: float) -> void: #Perform BFS over all the nodes and register the ones that are visible.
	loaded_chunks.clear()
	var node_index := _find_node_index(Name)
	var start_node := tree[node_index]
	var nodeXYZ := Vector3.ZERO
	var nodeRotation := Basis.IDENTITY
	if _render_distance(start_node, nodeXYZ, viewer) < MaxDist:
		loaded_chunks.append(_loaded_chunk(start_node.Name, nodeXYZ, nodeRotation, start_node.DataIndex))
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
		if node.ChildType == "tetrahedron":
			for child_index in range(node.children.size()):
				var child := node.children[child_index]
				var local_position: Vector3 = TETRAHEDRON_POSITIONS[child_index] * node.Radius
				var child_position := node_position + node_rotation * local_position
				var child_rotation := node_rotation * child.RotMatrix
				if _render_distance(child, child_position, viewer) < MaxDist:
					loaded_chunks.append(_loaded_chunk(child.Name, child_position, child_rotation, child.DataIndex))
				if _ball_distance(child_position, child.Radius, viewer) < MaxDist:
					queue.append({
						"node": child,
						"position": child_position,
						"rotation": child_rotation,
					})
	_sync_loaded_islands()


func _find_node_index(Name: String) -> int: # finds the node index based on the Name.
	for node_index in range(tree.size()):
		if tree[node_index].Name == Name:
			return node_index
	return -1
func _next_node_name() -> String: # generate a unique node Name. For now: n0, n1, n2, n3, ...
	var generated_name := "n" + str(next_node_id)
	next_node_id += 1
	return generated_name
func _delete_descendants(node: TreeNode) -> void: # the root node itself isnt included
	for child in node.children:
		_delete_descendants(child)
		tree.erase(child)
	node.children.clear()
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
			var new_island := island_scene.instantiate() as Node3D
			new_island.name = chunk_name
			new_island.set_meta("DataIndex", chunk["DataIndex"])
			add_child(new_island)
			loaded_islands[chunk_name] = new_island
		var island: Node3D = loaded_islands[chunk_name]
		island.global_transform = Transform3D(chunk["rotation"], chunk["position"])
	for chunk_name in loaded_islands.keys():
		if not requested_islands.has(chunk_name):
			var island_to_remove: Node3D = loaded_islands[chunk_name]
			island_to_remove.queue_free()
			loaded_islands.erase(chunk_name)
func _loaded_chunk(Name: String, position: Vector3, rotation: Basis, data_index: int) -> Dictionary: #compact chunk data into a dict, making it suitable for adding to loaded_chunks[] list
	return {
		"Name": Name,
		"position": position,
		"rotation": rotation,
		"DataIndex": data_index,
	}


func _ready() -> void: # This is where I'll create an initial structure for now.
	var root := TreeNode.new("root", "tetrahedron", true, 0, 10.0, Basis.IDENTITY, "", true)
	tree.append(root)
	add_tetrahedron_preset(root.Name)
	add_tetrahedron_preset(root.children[0].Name)
	add_tetrahedron_preset(root.children[1].Name)
func _process(_delta: float) -> void:
	BFS(
		"root",
		$"../EnvironmentManager/Camera3D".global_position,
		20.0
	)
