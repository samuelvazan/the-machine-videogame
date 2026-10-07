# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove or add comments.
# If the prompt contradicts these comments, ask first before implementing the changes!

# camera movement placeholder

extends Camera3D

@export var move_speed := 1.0
@export var rotate_speed := 1.5

var editor = false
var dragging = false
var velocity := Vector3.ZERO

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event):
	if event.is_action_pressed("mode"):
		editor = !editor
	
	# Release mouse
	if event.is_action_pressed("ui_cancel"):
		dragging = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Recapture on click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			dragging = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			dragging = false

# Editor camera implemented
	if event is InputEventMouseMotion and dragging:
		rotation.y -= event.relative.x * 0.003
		rotation.x -= event.relative.y * 0.003
		rotation.x = clamp(rotation.x, -1.5, 1.5)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			move_speed *= 1.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			move_speed *= 0.9
		move_speed = clamp(move_speed, 0.1, 100.0)

func _process(delta):
	# Movement relative to where the camera is facing.
	var input_vector := Vector3(
		Input.get_axis("camLeft", "camRight"),
		Input.get_axis("camDown", "camUp"),
		-Input.get_axis("camBackward", "camForward")
	)
	
	var direction := basis * input_vector
	if direction.length() > 1.0:
		direction = direction.normalized()
	
	velocity = velocity.lerp(direction * move_speed, 1.0 - exp(-10.0 * delta))
	position += velocity * delta
