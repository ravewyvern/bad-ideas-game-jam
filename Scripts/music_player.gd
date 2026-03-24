extends AudioStreamPlayer



func _process(_delta: float) -> void:
	if not playing :
		play()
		
func _physics_process(_delta: float) -> void:
	volume_linear = GlobalVariables.music_volume
