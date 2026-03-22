extends Node3D

@onready var arrow : PackedScene = load("res://Scenes/Bullet.tscn")
@onready var box = get_node("..").get_node("Box")
@onready var range_ : Area3D = get_node("Range")

var targets : Array[Area3D]
var target : Area3D

func _physics_process(_delta: float) -> void:
	if range_.has_overlapping_areas :
		print("Target detected")
		targets = range_.get_overlapping_areas()
		for potential_target in targets :
			if potential_target.has_method("take_damage()") :
				if potential_target.global_position - box.global_position < target.global_position - box.global_position :
					target = potential_target
					print("target is : " + str(target))
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
