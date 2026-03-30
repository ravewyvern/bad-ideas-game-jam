extends StaticBody3D

@onready var area: Area3D = $Area3D

@export var max_hp := 100
var hp := 0

@export var damage_distance := 5.0

func _ready():
	hp = max_hp


func _physics_process(_delta: float) -> void:
	if area.has_overlapping_bodies():
		for body in area.get_overlapping_bodies():
			if body.is_in_group("enemies"):
				if body.has_method("reach_box"):
					body.reach_box()


func take_damage(amount: float):
	hp -= amount
	print("Box HP:", hp)

	if hp <= 0:
		game_over()


func game_over():
	get_tree().change_scene_to_file("res://Scenes/Menus/GameOver.tscn")
