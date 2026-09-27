extends Node

enum Mode { HIERARCHY, STRUCTURE, TILES }

const RAY_LENGTH := 10000.0

@onready var camera: Camera3D = get_parent()
@onready var island_manager: IslandManager = $"../../../IslandManager"
@onready var mode_label: Label = $CanvasLayer/ModeLabel

var mode := Mode.HIERARCHY
var pending_click := -1
var pending_position := Vector2.ZERO


func _ready() -> void:
	_show_mode()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			mode = Mode.HIERARCHY
		KEY_2:
			mode = Mode.STRUCTURE
		KEY_3:
			mode = Mode.TILES
		_:
			return
	_show_mode()
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		pending_click = event.button_index
		pending_position = event.position
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if pending_click == -1:
		return
	var button := pending_click
	pending_click = -1
	var hit := _pick(pending_position)
	if hit.is_empty():
		return
	var island: Island = hit["island"]
	match mode:
		Mode.HIERARCHY:
			if button == MOUSE_BUTTON_LEFT:
				island_manager.toggle_tetrahedron_preset(island.tree_node_name)
		Mode.STRUCTURE:
			if button == MOUSE_BUTTON_LEFT:
				island.add_grid_map()
			else:
				island.remove_grid_map()
		Mode.TILES:
			island.set_tile_at(hit["position"], hit["normal"], button == MOUSE_BUTTON_RIGHT)


func _pick(screen_position: Vector2) -> Dictionary:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * RAY_LENGTH, 6)
	query.collide_with_areas = true
	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
	var nearest: Dictionary = {}
	var distance := RAY_LENGTH
	if not result.is_empty():
		var island := _island_from(result["collider"])
		if island != null:
			nearest = {"island": island, "position": result["position"], "normal": result["normal"]}
			if result["collider"] is Area3D:
				nearest["normal"] = _box_normal(island, result["position"])
			distance = origin.distance_to(result["position"])
	for candidate in island_manager.loaded_islands.values():
		var island := candidate as Island
		var local_origin := island.to_local(origin)
		if maxf(absf(local_origin.x), maxf(absf(local_origin.y), absf(local_origin.z))) >= 1.0:
			continue
		var local_direction := island.to_local(origin + direction) - local_origin
		for axis in range(3):
			if absf(local_direction[axis]) < 0.000001:
				continue
			var side := signf(local_direction[axis])
			var exit_distance := (side - local_origin[axis]) / local_direction[axis]
			if exit_distance > 0.0 and exit_distance < distance:
				distance = exit_distance
				var normal := Vector3.ZERO
				normal[axis] = side
				nearest = {"island": island, "position": origin + direction * distance, "normal": (island.global_basis * normal).normalized()}
	return nearest


func _island_from(node: Node) -> Island:
	while node != null and not node is Island:
		node = node.get_parent()
	return node as Island


func _box_normal(island: Island, position: Vector3) -> Vector3:
	var local := island.to_local(position)
	var axis := local.abs().max_axis_index()
	var normal := Vector3.ZERO
	normal[axis] = signf(local[axis])
	return (island.global_basis * normal).normalized()


func _show_mode() -> void:
	mode_label.text = ["1 Hierarchy: left click toggles children", "2 Island structure: left adds grid, right removes", "3 Tiles: left places, right erases"][mode]
