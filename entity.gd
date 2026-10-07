extends Node

const PRESETS := {
	0: preload("res://player.tscn"),
}

@export var data_index := -1
@export var init_info: Resource
@export var spawn_position := Vector3.ZERO
@export var visibility_range := 200.0
@export var suspend_delay := 2.0
@export var suspension_timeout := 9999999.0
var unseen_timhave made a severe and continuous lapse in judgement...
209
Reply
@SebastianCavolina
18 hours ago
Actually, The Louisiana State Lottery scandal was THE biggest state-wide scam in the 1800's. They sold tickets by mail, 90% of their money came from outside Louisiana. THey gathered a frickton of cash and the rigged the results, and people said it was legite := 0.0
var current_island: Island
var island_transform := Transform3D.IDENTITY
var physics_objects: Array[CollisionObject3D] = []
var local_roots: Array[Node3D] = []
var visual_roots: Array[Node3D] = []
var visual_anchors: Array[Node3D] = []
var visual_offsets: Array[Transform3D] = []
var previous_anchor_transforms: Array[Transform3D] = []
var original_top_levels: Dictionary = {}
var position_node: Node3D
var position_is_projected := false
var island_manager: IslandManager

func configure(new_data_index: int, new_init_info: Resource, new_spawn_position: Vector3) -> Error:
	data_index = new_data_index
	init_info = new_init_info
	spawn_position = new_spawn_position
	return _load_preset()

func _ready() -> void:
	process_priority = 100
	process_physics_priority = 100
	if get_child_count() == 0:
		var error := _load_preset()
		if error != OK:
			push_error("Could not load entity preset: " + str(data_index))
	physics_objects = PhysicsSpaceUtils.collect_collision_objects(self)
	_collect_visual_roots(self, false)
	_collect_local_roots(self)
	for object in physics_objects:
		if object is PhysicsBody3D:
			position_node = object
			break
	if position_node == null:
		position_node = _find_camera(self)
	if position_node == null:
		for child in get_children():
			if child is Node3D:
				position_node = child
				break
	if not position_node is PhysicsBody3D:
		var node: Node = position_node
		while node != null:
			if node is Node3D and visual_roots.has(node):
				position_is_projected = true
				break
			node = node.get_parent()
	island_manager = get_node_or_null("../../IslandManager") as IslandManager
	_refresh_nearest_island()

func _load_preset() -> Error:
	if not PRESETS.has(data_index):
		return ERR_INVALID_PARAMETER
	var preset: Node = PRESETS[data_index].instantiate()
	if preset == null:
		return ERR_CANT_CREATE
	add_child(preset)
	if preset is Node3D:
		preset.position = spawn_position
	_set_owner_recursively(preset)
	return OK

func _set_owner_recursively(node: Node) -> void:
	node.owner = self
	for child in node.get_children(true):
		_set_owner_recursively(child)

func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var camera := _find_camera(child)
		if camera != null:
			return camera
	return null

func _collect_visual_roots(node: Node, projected_ancestor: bool) -> void:
	var projected := projected_ancestor
	if node is PhysicsBody3D or node is Area3D:
		projected = false
	elif node is VisualInstance3D or node is Camera3D or node is Light3D or node is AudioStreamPlayer3D:
		if not projected:
			visual_roots.append(node)
			var parent := node.get_parent()
			while parent != null and not parent is Node3D:
				parent = parent.get_parent()
			visual_anchors.append(parent as Node3D)
		projected = true
	for child in node.get_children():
		_collect_visual_roots(child, projected)

func _collect_local_roots(node: Node) -> void:
	for child in node.get_children():
		if child is Node3D:
			if not child is PhysicsBody3D and not child is Area3D and not visual_roots.has(child):
				local_roots.append(child)
		else:
			_collect_local_roots(child)

func get_world_position() -> Vector3:
	if position_node == null:
		return spawn_position
	if current_island == null or position_is_projected:
		return position_node.global_position
	var transform := island_transform
	if is_instance_valid(current_island) and current_island.is_inside_tree():
		transform = current_island.global_transform
	return transform * position_node.global_position

func _nearest_island(world_position: Vector3) -> Island:
	if island_manager == null:
		return null
	var nearest: Island
	var best_distance := INF
	for candidate in island_manager.loaded_islands.values():
		var island := candidate as Island
		if island == null or not is_instance_valid(island) or not island.is_inside_tree() or island.is_queued_for_deletion():
			continue
		var distance := absf(world_position.distance_to(island.global_position) - island.scale.x)
		if distance < best_distance:
			best_distance = distance
			nearest = island
	return nearest

func _refresh_nearest_island() -> void:
	var nearest := _nearest_island(get_world_position())
	if nearest != null and nearest != current_island:
		_switch_island(nearest)

func _switch_island(new_island: Island) -> void:
	if current_island != null and is_instance_valid(current_island):
		_project_visuals()
	var world_visuals: Array[Transform3D] = []
	for root in visual_roots:
		world_visuals.append(root.global_transform)
	if current_island == null:
		for object in physics_objects:
			original_top_levels[object] = object.top_level
		for root in visual_roots:
			original_top_levels[root] = root.top_level
	var from_transform := island_transform if current_island != null else Transform3D.IDENTITY
	var to_transform := new_island.global_transform
	PhysicsSpaceUtils.move_objects_to_space(physics_objects, from_transform, to_transform, new_island.physics_space)
	for root in local_roots:
		root.global_transform = PhysicsSpaceUtils.to_island_local(to_transform, PhysicsSpaceUtils.to_world_transform(from_transform, root.global_transform))
	visual_offsets.clear()
	previous_anchor_transforms.clear()
	for index in range(visual_roots.size()):
		var root := visual_roots[index]
		var anchor := visual_anchors[index]
		var anchor_transform := anchor.global_transform if anchor != null else Transform3D.IDENTITY
		var local_transform := PhysicsSpaceUtils.to_island_local(to_transform, world_visuals[index])
		visual_offsets.append(anchor_transform.affine_inverse() * local_transform)
		previous_anchor_transforms.append(anchor_transform)
		root.top_level = true
		root.global_transform = world_visuals[index]
	current_island = new_island
	island_transform = to_transform

func _physics_process(_delta: float) -> void:
	_refresh_nearest_island()

func _process(delta: float) -> void:
	_project_visuals()
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if is_ancestor_of(camera):
		unseen_time = 0.0
		return
	var position := get_world_position()
	if camera.global_position.distance_to(position) <= visibility_range and camera.is_position_in_frustum(position):
		unseen_time = 0.0
		return
	unseen_time += delta
	if unseen_time >= suspend_delay:
		var manager := get_parent()
		if manager != null and manager.has_method("suspend_entity"):
			manager.suspend_entity(name)

func _project_visuals() -> void:
	if current_island == null or not is_instance_valid(current_island):
		return
	var new_transform := current_island.global_transform
	for index in range(visual_roots.size()):
		var root := visual_roots[index]
		var previous_local := PhysicsSpaceUtils.to_island_local(island_transform, root.global_transform)
		visual_offsets[index] = previous_anchor_transforms[index].affine_inverse() * previous_local
		var anchor := visual_anchors[index]
		var anchor_transform := anchor.global_transform if anchor != null else Transform3D.IDENTITY
		root.global_transform = PhysicsSpaceUtils.to_world_transform(new_transform, anchor_transform * visual_offsets[index])
		previous_anchor_transforms[index] = anchor_transform
	island_transform = new_transform

func prepare_for_pack() -> void:
	if current_island == null:
		return
	_project_visuals()
	var world_transforms: Dictionary = {}
	for root in local_roots:
		world_transforms[root] = PhysicsSpaceUtils.to_world_transform(island_transform, root.global_transform)
	for object in physics_objects:
		world_transforms[object] = PhysicsSpaceUtils.to_world_transform(island_transform, object.global_transform)
	for root in visual_roots:
		world_transforms[root] = root.global_transform
	_restore_world_transforms(self, world_transforms)
	current_island = null

func _restore_world_transforms(node: Node, world_transforms: Dictionary) -> void:
	if world_transforms.has(node):
		var spatial := node as Node3D
		if original_top_levels.has(node):
			spatial.top_level = original_top_levels[node]
		spatial.global_transform = world_transforms[node]
	for child in node.get_children():
		_restore_world_transforms(child, world_transforms)
