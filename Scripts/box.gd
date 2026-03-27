extends StaticBody3D

@onready var area : Area3D = $Area3D

@export var max_hp := 100
var hp := 0

func _ready():
	hp = max_hp

func _physics_process(_delta: float) -> void:
	if area.has_overlapping_areas() :
		for creature in area.get_overlapping_areas() :
			if creature.has_method("reach_box") :
				creature.reach_box()
				
func take_damage(amount: float):
	hp -= amount

	if hp <= 0:
		game_over()
		
func game_over():
	get_tree().change_scene_to_file("res://GameOver.tscn")
