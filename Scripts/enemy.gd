extends CharacterBody3D

@export var health = 50

func _physics_process(delta):

	# Add gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

# Receive damage based on bullet "damage" var.
func take_damage(amount):
	health -= amount
	print("Damage:", amount)

	if health <= 0:
		die()

func die():
	queue_free()
