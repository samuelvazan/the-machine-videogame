class_name Island
extends Node3D

const SPHERE_SCENE := preload("res://assets/sphere.glb")
const FULL_SPHERE_SCENE := preload("res://assets/fullsphere.glb")

var data_idx: int = -1


func _ready() -> void:
	match data_idx:
		-1:
			add_child(SPHERE_SCENE.instantiate())
		1:
			add_child(FULL_SPHERE_SCENE.instantiate())
