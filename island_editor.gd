extends Node

enum Mode { HIERARCHY, STRUCTURE, TILES }

const RAY_LENGTH := 10000.0

@onready var camera: Camera3D = get_parent()
@onready var island_manager: IslandManager = $"../../../../../IslandManager"
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
				island_manager.toggle_preset(island.tree_node_name)
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
	var nearest: Dictionary = {}
	var distance := RAY_LENGTH
	var nearest_tile: Dictionary = {}
	var tile_distance := RAY_LENGTH
	for candidate in island_manager.loaded_islands.values():
		var island := candidate as Island
		if island == null or not is_instance_valid(island) or not island.physics_space.is_valid():
			continue
		var local_origin := island.to_local(origin)
		var local_end := island.to_local(origin + direction * RAY_LENGTH)
		var tile_query := PhysicsRayQueryParameters3D.create(local_origin, local_end, 4)
		var tile_result := PhysicsServer3D.space_get_direct_state(island.physics_space).intersect_ray(tile_query)
		if not tile_result.is_empty():
			var tile_position: Vector3 = island.global_transform * tile_result["position"]
			var hit_distance := origin.distance_to(tile_position)
			if hit_distance < tile_distance:
				tile_distance = hit_distance
				var tile_normal: Vector3 = (island.global_transform.basis.inverse().transposed() * tile_result["normal"]).normalized()
				nearest_tile = {"island": island, "position": tile_position, "normal": tile_normal}
				if hit_distance < distance:
					distance = hit_distance
					nearest = nearest_tile
		var area_query := PhysicsRayQueryParameters3D.create(local_origin, local_end, 2)
		area_query.collide_with_areas = true
		var area_result := PhysicsServer3D.space_get_direct_state(island.physics_space).intersect_ray(area_query)
		if not area_result.is_empty():
			var area_position: Vector3 = island.global_transform * area_result["position"]
			var area_distance := origin.distance_to(area_position)
			if area_distance < distance:
				distance = area_distance
				nearest = {"island": island, "position": area_position, "normal": (area_position - island.global_position).normalized()}
		if local_origin.length_squared() >= 1.0:
			continue
		var local_direction := island.to_local(origin + direction) - local_origin
		var a := local_direction.length_squared()
		var b := local_origin.dot(local_direction)
		var exit_distance := (-b + sqrt(b * b + a * (1.0 - local_origin.length_squared()))) / a
		if exit_distance > 0.0 and exit_distance < distance:
			distance = exit_distance
			var position := origin + direction * distance
			nearest = {"island": island, "position": position, "normal": (position - island.global_position).normalized()}
	return nearest_tile if mode == Mode.TILES and not nearest_tile.is_empty() else nearest


func _show_mode() -> void:
	mode_label.text = ["1 Hierarchy: left click toggles children", "2 Island structure: left adds grid, right removes", "3 Tiles: left places, right erases"][mode]
