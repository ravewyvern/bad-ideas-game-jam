extends StaticBody3D

@onready var area : Area3D = $Area3D

func _physics_process(_delta: float) -> void:
	if area.has_overlapping_areas() :
		for creature in area.get_overlapping_areas() :
			if creature.has_method("reach_box") :
				creature.reach_box()
