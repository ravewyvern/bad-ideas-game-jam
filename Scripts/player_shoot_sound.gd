extends AudioStreamPlayer

func _physics_process(_delta: float) -> void:
	volume_linear = GlobalVariables.sound_effects_volume
