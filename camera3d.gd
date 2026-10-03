# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove or add comments.
# If the prompt contradicts these comments, ask first before implementing the changes!

# camera movement placeholder

extends Camera3D

@export var move_speed := 10.0
@export var rotate_speed := 1.5

func _ready():
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# Release mouse
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Recapture on click
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Editor camera implemented
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * 0.003
		rotation.x -= event.relative.y * 0.003
		rotation.x = clamp(rotation.x, -1.5, 1.5)

func _process(delta):
	# Movement relative to where the camera is facing.
	position += basis.x * Input.get_axis("camLeft", "camRight") * move_speed * delta
	position += basis.y * Input.get_axis("camDown", "camUp") * move_speed * delta
	position += -basis.z * Input.get_axis("camBackward", "camForward") * move_speed * delta
