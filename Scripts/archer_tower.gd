extends Node3D

@onready var arrow : PackedScene = load("res://Scenes/Bullet.tscn")
@onready var box = get_node("..").get_node("Box")
@onready var range_ : Area3D = get_node("Range")

var targets : Array[Area3D]
var target : CharacterBody3D

func _physics_process(_delta: float) -> void:
	if range_.has_overlapping_areas :
		targets = range_.get_overlapping_areas()
		print("area3D found")
		for potential_target in targets :
			var parent = potential_target.get_parent()
			if potential_target.has_method("take_damage") :
				print("target found")
				if target :
					if parent.global_position - box.global_position < target.global_position - box.global_position :
						target = parent
						print("target is : " + str(target))
				else : 
					target = parent
					print("target is : " + str(target))
			else : print("area doesn't have method")
		if target :
			var bullet = arrow.instantiate()
			get_tree().current_scene.add_child(bullet)

			bullet.global_transform.origin = range_.global_transform.origin

			look_at(target.global_position)
			var shoot_direction = -global_transform.basis.z
			bullet.look_at(bullet.global_position + shoot_direction, Vector3.UP)
			bullet.direction = shoot_direction
			await get_tree().create_timer(1).timeout
	else : 
		target = null
