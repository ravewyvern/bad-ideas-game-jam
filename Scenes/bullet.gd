extends Area3D

@export var speed = 40.0
@export var lifetime = 3.0

var direction = Vector3.ZERO

# Destroy after 3 seconds.
func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	translate(direction * speed * delta)
