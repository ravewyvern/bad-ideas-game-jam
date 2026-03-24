extends HSlider

@onready var test_sounds : AudioStreamPlayer = get_parent().get_node("TestSounds")

func _physics_process(_delta: float) -> void:
	GlobalVariables.music_volume = value / 10
