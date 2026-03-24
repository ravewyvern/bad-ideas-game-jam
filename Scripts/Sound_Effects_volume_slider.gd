extends HSlider

@onready var test_sounds : AudioStreamPlayer = get_parent().get_node("TestSounds")

func _physics_process(_delta: float) -> void:
	GlobalVariables.sound_effects_volume = value / 10
	
func _process(_delta: float) -> void:
	await value_changed
	test_sounds.stream = load("res://Assets/Sounds/3-Dart Thwamp +1.wav")
	test_sounds.play()
