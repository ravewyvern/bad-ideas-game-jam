extends Camera3D

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("Aim") :
		fov = 50
	else :
		fov = 110
