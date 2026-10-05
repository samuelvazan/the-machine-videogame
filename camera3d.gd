# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove or add comments.
# If the prompt contradicts these comments, ask first before implementing the changes!

# camera movement placeholder

extends Camera3D

@export var move_speed := 1.0
@export var rotate_speed := 1.5

func _ready():
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# Release mouse
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Toggle mouse capture
	if event.is_action_pressed("EditorToggle"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_object_local(Vector3.UP, -event.relative.x * 0.003)
		rotate_object_local(Vector3.RIGHT, -event.relative.y * 0.003)

func _process(delta):
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE: #If editor==true, rotate using arrow keys. Else, mouse position is used.
		rotate_object_local(Vector3.UP, -Input.get_axis("camRleft", "camRright") * rotate_speed * delta)
		rotate_object_local(Vector3.RIGHT, -Input.get_axis("camRup", "camRdown") * rotate_speed * delta)
	position += basis.x * Input.get_axis("camLeft", "camRight") * move_speed * delta
	position += basis.y * Input.get_axis("camDown", "camUp") * move_speed * delta
	position += -basis.z * Input.get_axis("camBackward", "camForward") * move_speed * delta
