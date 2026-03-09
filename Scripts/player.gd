extends CharacterBody3D

@export var hp : int = 100
@export var Bullet : PackedScene
@export var BulletSpawnPoint : Node3D
@onready var Camera = $Head/Camera3D
@onready var hpbar = $HpBar

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const sensitivity = 0.01

# aerial camera movement speed
const DRAG_SPEED = 0.05

var fallheight : int

# stores if aerial view is active
var top_view_enabled : bool = false

# stores if the mouse is dragging
var dragging : bool = false

# stores the normal camera position and rotation
var normal_camera_position : Vector3
var normal_camera_rotation : Vector3


func _ready() -> void:
	hp = 100
	
	# captures mouse for FPS camera
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# stores normal camera transform
	normal_camera_position = Camera.position
	normal_camera_rotation = Camera.rotation


func _unhandled_input(event: InputEvent) -> void:
	
	# disables FPS camera movement when in aerial view
	if top_view_enabled:
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		Camera.rotate_x(-event.relative.y * sensitivity)
		Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta: float) -> void:
	
	# disables player movement when in aerial view
	if top_view_enabled:
		return
	
	#sets hp bar to hp value
	hpbar.value = hp
	
	# Add the gravity and counts fall length to determine fall damage
	if not is_on_floor():
		fallheight += 1
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Move.Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("Move.Left", "Move.Right", "Move.Forward", "Move.Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0
		velocity.z = 0
	
	#fall damage
	if is_on_floor() :
		if fallheight > 100 :
			@warning_ignore("narrowing_conversion")
			hp -= 0.2 * fallheight
		fallheight = 0

	move_and_slide()


func _input(event):
	
	# toggles aerial view
	if event.is_action_pressed("Toggle.TopView"):
		toggle_top_view()
	
	# handles aerial camera movement
	if top_view_enabled:
		
		# starts dragging when mouse button is pressed
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				dragging = event.pressed
		
		# moves camera while dragging (only on map plane X/Z)
		if event is InputEventMouseMotion and dragging:
			
			# moves camera left/right
			Camera.global_position.x -= event.relative.x * DRAG_SPEED
			
			# moves camera forward/back on the map
			Camera.global_position.z -= event.relative.y * DRAG_SPEED
		
		return
	
	if event.is_action_pressed("shoot"):
		shoot()


func toggle_top_view():
	
	# toggles aerial camera mode
	top_view_enabled = !top_view_enabled
	
	if top_view_enabled:
		
		# moves camera above the player
		Camera.global_position = global_position + Vector3(0, 15, 0)
		
		# rotates camera to look straight down
		Camera.rotation_degrees = Vector3(-90, 0, 0)
		
		# releases mouse so player can drag the camera
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	else:
		
		# stops dragging
		dragging = false
		
		# restores normal camera transform
		Camera.position = normal_camera_position
		Camera.rotation = normal_camera_rotation
		
		# captures mouse again for FPS control
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func shoot():
	# Bullet spawn.
	var bullet = Bullet.instantiate()
	get_tree().current_scene.add_child(bullet)

	# Bullet position.
	bullet.global_transform.origin = BulletSpawnPoint.global_transform.origin
	
	var shoot_direction = -Camera.global_transform.basis.x
	bullet.look_at(bullet.global_position + shoot_direction, Camera.global_transform.basis.y)
	bullet.direction = shoot_direction
	
	# Bullet spawns at the front of the camera.
	bullet.direction = -Camera.global_transform.basis.z
