extends Camera3D

@export var move_speed := 10.0
@export var rotate_speed := 1.5

func _process(delta):
	# Movement relative to where the camera is facing.
	position += basis.x * Input.get_axis("camLeft", "camRight") * move_speed * delta
	position += basis.y * Input.get_axis("camDown", "camUp") * move_speed * delta
	position += -basis.z * Input.get_axis("camBackward", "camForward") * move_speed * delta

	# Rotation.
	rotation.x += Input.get_axis("camRdown", "camRup") * rotate_speed * delta
	rotation.y += Input.get_axis("camRright", "camRleft") * rotate_speed * delta
	rotation.z += Input.get_axis("camRbackward", "camRforward") * rotate_speed * delta
