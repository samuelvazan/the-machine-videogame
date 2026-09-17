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
	var Name: String
	var Type: String
	var Parentable: bool
	var DataIndex: int
	var Radius: float
	var RotMatrix: Basis
	var ChildType: String
	var children: Array[TreeNode]

	func _init(
		new_name: String,
		new_type: String,
		new_parentable: bool,
		new_data_index: int,
		new_radius: float,
		new_rot_matrix: Basis,
		new_child_type: String = ""
	) -> void:
		Name = new_name
		Type = new_type
		Parentable = new_parentable
		DataIndex = new_data_index
		Radius = new_radius
		RotMatrix = new_rot_matrix
		ChildType = new_child_type
		children = []

@export var island_scene: PackedScene

var tree: Array[TreeNode] = []
var loaded_chunks: Array[Dictionary] = []
var next_node_id := 0


func add_tetrahedron_preset(Name: String) -> void:
	var node_index := _find_node_index(Name)
	var parent := tree[node_index]
	if parent.Type == "tetrahedron" and parent.Parentable:
		parent.Parentable = false
		parent.ChildType = "tetrahedron"
		for _child_index in range(4):
			var child := TreeNode.new(
				_next_node_name(),
				"tetrahedron",
				true,
				-1,
				parent.Radius * TETRAHEDRON_RADIUS_SCALE,
				Basis.IDENTITY
			)
			parent.children.append(child)
			tree.append(child)
		var core := TreeNode.new(
			_next_node_name(),
			"core",
			false,
			-1,
			parent.Radius * CORE_RADIUS_SCALE,
			Basis.IDENTITY
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


func BFS(Name: String, viewer: Vector3, MaxDist: float) -> void:
	loaded_chunks.clear()
	var node_index := _find_node_index(Name)
	var start_node := tree[node_index]
	var nodeXYZ := Vector3.ZERO
	var nodeRotation := Basis.IDENTITY
	if _sphere_distance(nodeXYZ, start_node.Radius, viewer) < MaxDist:
		loaded_chunks.append(_loaded_chunk(nodeXYZ, nodeRotation, start_node.DataIndex))
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
				if _sphere_distance(child_position, child.Radius, viewer) < MaxDist:
					loaded_chunks.append(_loaded_chunk(child_position, child_rotation, child.DataIndex))
				if _ball_distance(child_position, child.Radius, viewer) < MaxDist:
					queue.append({
						"node": child,
						"position": child_position,
						"rotation": child_rotation,
					})


func _find_node_index(Name: String) -> int: # finds the node index based on the Name.
	for node_index in range(tree.size()):
		if tree[node_index].Name == Name:
			return node_index
	return -1
func _next_node_name() -> String: # 
	var generated_name := "n" + str(next_node_id)
	next_node_id += 1
	return generated_name
func _delete_descendants(node: TreeNode) -> void:
	for child in node.children:
		_delete_descendants(child)
		tree.erase(child)
	node.children.clear()
func _ball_distance(position: Vector3, radius: float, viewer: Vector3) -> float:
	return maxf(position.distance_to(viewer) - radius, 0.0)
func _sphere_distance(position: Vector3, radius: float, viewer: Vector3) -> float:
	return absf(position.distance_to(viewer) - radius)
func _loaded_chunk(position: Vector3, rotation: Basis, data_index: int) -> Dictionary:
	return {
		"position": position,
		"rotation": rotation,
		"DataIndex": data_index,
	}
