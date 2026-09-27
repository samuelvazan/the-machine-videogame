class_name IslandPresets
extends RefCounted

const PRESETS := {
	"tetrahedron": {
		"parent_type": "tetrahedron",
		"children": [
			{"type": "tetrahedron", "parentable": true, "radius_scale": 0.446875, "offset": Vector3(0, 0, -0.550509375)},
			{"type": "tetrahedron", "parentable": true, "radius_scale": 0.446875, "offset": Vector3(0.519025, 0, 0.183503125)},
			{"type": "tetrahedron", "parentable": true, "radius_scale": 0.446875, "offset": Vector3(-0.2595125, 0.449490625, 0.183503125)},
			{"type": "tetrahedron", "parentable": true, "radius_scale": 0.446875, "offset": Vector3(-0.2595125, -0.449490625, 0.183503125)},
			{"type": "core", "parentable": false, "radius_scale": 0.1, "offset": Vector3.ZERO},
		]
	}
}
