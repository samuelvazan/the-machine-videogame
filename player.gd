# This also kinda controlls the camera* (well, camera instantiated from Player, therefore it moves automatically, no code here actually)

extends CharacterBody3D

@export var move_speed := 20.0
@export var rotate_speed := 1.5

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("EditorToggle"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera.rotate_object_local(Vector3.UP, -event.relative.x * 0.003)
		camera.rotate_object_local(Vector3.RIGHT, -event.relative.y * 0.003)

func _process(delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		camera.rotate_object_local(Vector3.UP, -Input.get_axis("camRleft", "camRright") * rotate_speed * delta)
		camera.rotate_object_local(Vector3.RIGHT, -Input.get_axis("camRup", "camRdown") * rotate_speed * delta)

func _physics_process(_delta: float) -> void:
	var input_direction := Vector3(
		Input.get_axis("camLeft", "camRight"),
		Input.get_axis("camDown", "camUp"),
		-Input.get_axis("camBackward", "camForward")
	)
	var world_velocity := camera.global_basis.orthonormalized() * input_direction * move_speed
	var entity := get_parent()
	if entity != null and entity.get("current_island") != null:
		var island_transform: Transform3D = entity.get("island_transform")
		velocity = island_transform.basis.inverse() * world_velocity
	else:
		velocity = world_velocity
	move_and_slide()
