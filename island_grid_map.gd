class_name IslandGridMap
extends GridMap

const COLLISION_BODY_NAME := "TileCollision"

var cell_shapes: Dictionary = {}


func rebuild_collision_shapes() -> void:
	var body := get_node_or_null(COLLISION_BODY_NAME) as StaticBody3D
	if body == null:
		return
	for child in body.get_children():
		if child is CollisionShape3D:
			body.remove_child(child)
			child.queue_free()
	cell_shapes.clear()
	for cell in get_used_cells():
		update_collision_cell(cell)


func update_collision_cell(cell: Vector3i) -> void:
	var body := get_node_or_null(COLLISION_BODY_NAME) as StaticBody3D
	if body == null:
		return
	for shape in cell_shapes.get(cell, []):
		if is_instance_valid(shape):
			body.remove_child(shape)
			shape.queue_free()
	cell_shapes.erase(cell)
	var item := get_cell_item(cell)
	if item == INVALID_CELL_ITEM or mesh_library == null:
		return
	var item_shapes := mesh_library.get_item_shapes(item)
	var cell_transform := Transform3D(get_cell_item_basis(cell).scaled(Vector3.ONE * cell_scale), map_to_local(cell))
	var created_shapes: Array[CollisionShape3D] = []
	for index in range(0, item_shapes.size(), 2):
		var tile_shape := item_shapes[index] as Shape3D
		if tile_shape == null:
			continue
		var collision := CollisionShape3D.new()
		collision.shape = tile_shape
		var tile_transform: Transform3D = item_shapes[index + 1]
		collision.transform = cell_transform * tile_transform
		body.add_child(collision)
		created_shapes.append(collision)
	if not created_shapes.is_empty():
		cell_shapes[cell] = created_shapes
