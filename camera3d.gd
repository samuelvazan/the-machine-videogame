# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

#makes the camera move. Its just a placeholder for the eventual camera movement.

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
