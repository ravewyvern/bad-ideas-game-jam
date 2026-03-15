extends VBoxContainer

# add references to all buttons
@onready var level: Button = $level
@onready var options: Button = $options
@onready var credits: Button = $credits
@onready var quit: Button = $quit

func _on_level_button_down() -> void:
	# load into main game, should eventually open a menu to select which level to play
	get_tree().change_scene_to_file("res://Scenes/Maps/Level_1.tscn")

func _on_options_button_down() -> void:
	 # many add options menu eventually? if not just delete this and the button
	print("options not implemented yet")

func _on_credits_button_down() -> void:
	# menu with credits to everyone
	print("credits not implemented yet")

func _on_quit_button_down() -> void:
	get_tree().quit()
