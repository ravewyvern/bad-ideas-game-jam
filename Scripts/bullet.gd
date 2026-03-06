extends Area3D

@export var speed = 30.0
@export var lifetime = 3.0
@export var damage = 10

var direction = Vector3.ZERO

func _ready():
	# Destroy after 3 seconds
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	global_translate(direction * speed * delta)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)

	queue_free()
