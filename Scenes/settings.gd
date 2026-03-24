extends Control

@onready var back = get_node("Back")

func _on_back_button_down() :
	get_tree().change_scene_to_file("res://Scenes/Menus/Main Menu.tscn")
