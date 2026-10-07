# These are the utility functions for the game physics (RIDs and such)

class_name PhysicsSpaceUtils
extends RefCounted


static func collect_collision_objects(root: Node) -> Array[CollisionObject3D]:
	var objects: Array[CollisionObject3D] = []
	_collect_collision_objects(root, objects)
	return objects


static func _collect_collision_objects(node: Node, objects: Array[CollisionObject3D]) -> void:
	if node is PhysicsBody3D or node is Area3D:
		objects.append(node)
	for child in node.get_children():
		_collect_collision_objects(child, objects)


static func assign_space(object: CollisionObject3D, space: RID) -> void:
	if object is PhysicsBody3D:
		PhysicsServer3D.body_set_space(object.get_rid(), space)
	elif object is Area3D:
		PhysicsServer3D.area_set_space(object.get_rid(), space)


static func to_island_local(island_transform: Transform3D, world_transform: Transform3D) -> Transform3D:
	return island_transform.affine_inverse() * world_transform


static func to_world_transform(island_transform: Transform3D, local_transform: Transform3D) -> Transform3D:
	return island_transform * local_transform


static func convert_velocity(velocity: Vector3, from_island: Transform3D, to_island: Transform3D) -> Vector3:
	return to_island.basis.inverse() * (from_island.basis * velocity)


static func convert_direction(direction: Vector3, from_island: Transform3D, to_island: Transform3D) -> Vector3:
	return to_island.basis.orthonormalized().inverse() * (from_island.basis.orthonormalized() * direction)


static func move_objects_to_space(objects: Array[CollisionObject3D], from_island: Transform3D, to_island: Transform3D, space: RID) -> void:
	var transforms: Array[Transform3D] = []
	var linear_velocities: Array[Vector3] = []
	var angular_velocities: Array[Vector3] = []
	for object in objects:
		transforms.append(to_island_local(to_island, to_world_transform(from_island, object.global_transform)))
		var linear_velocity := Vector3.ZERO
		var angular_velocity := Vector3.ZERO
		if object is CharacterBody3D:
			linear_velocity = object.velocity
		elif object is RigidBody3D:
			linear_velocity = object.linear_velocity
			angular_velocity = object.angular_velocity
		elif object is StaticBody3D:
			linear_velocity = object.constant_linear_velocity
			angular_velocity = object.constant_angular_velocity
		linear_velocities.append(linear_velocity)
		angular_velocities.append(angular_velocity)
	for index in range(objects.size()):
		var object := objects[index]
		object.top_level = true
		object.global_transform = transforms[index]
		assign_space(object, space)
		var linear_velocity := convert_velocity(linear_velocities[index], from_island, to_island)
		var angular_velocity := convert_direction(angular_velocities[index], from_island, to_island)
		if object is CharacterBody3D:
			object.velocity = linear_velocity
			object.up_direction = convert_direction(object.up_direction, from_island, to_island)
		elif object is RigidBody3D:
			object.linear_velocity = linear_velocity
			object.angular_velocity = angular_velocity
		elif object is StaticBody3D:
			object.constant_linear_velocity = linear_velocity
			object.constant_angular_velocity = angular_velocity
