extends AudioStreamPlayer

func _process(_delta: float) -> void:
	if not playing :
		play()
