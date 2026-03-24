extends Area3D

@onready var enemy = get_node(".")

func take_damage(damage : int) :
	enemy.health -= damage
