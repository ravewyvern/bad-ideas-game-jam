extends CharacterBody3D

@export var Bullet : PackedScene
@export var BulletSpawnPoint : Node3D
@onready var Camera = $Head/Camera3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const sensitivity = 0.03

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		Camera.rotate_x(-event.relative.y * sensitivity)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Move.Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Move.Left", "Move.Right", "Move.Forward", "Move.Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func _input(event):
	if event.is_action_pressed("shoot"):
		shoot()

func shoot():
	# Bullet spawn.
	var bullet = Bullet.instantiate()
	get_tree().current_scene.add_child(bullet)

	# Bullet position.
	bullet.global_transform.origin = BulletSpawnPoint.global_transform.origin
	
	# Bullet spawns at the front of the camera.
	bullet.direction = -Camera.global_transform.basis.z
