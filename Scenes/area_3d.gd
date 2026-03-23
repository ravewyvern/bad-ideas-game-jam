extends Area3D

@onready var player = get_node(".")

func take_damage(damage : int) :
	player.hp -= damage
