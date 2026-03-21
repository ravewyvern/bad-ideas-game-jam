extends CharacterBody3D

@export var stam : int
@export var hp : int = 100
@export var Bullet : PackedScene
@export var BulletSpawnPoint : Node3D

# Tower list (5 towers)
@export var TowerPlaceholders : Array[PackedScene] = []
var selected_tower_index : int = 0

@onready var Camera = $Head/Camera3D
@onready var hpbar = $HpBar
@onready var stambar = $StamBar
@onready var Mags = $Mags
@onready var Ammo = $AmmoInMag
@onready var reloadbar = $ReloadBar
@onready var reload_time = $Timer

class StatusEffect:
	var name : String
	var duration : float
	var magnitude : int

class towercall:
	var input : Array[String]
	var index : int

# Active status effects list
var Effects : Array[StatusEffect] = []

# Tower input buffer
var TowerInput : Array[String] = []
var is_tower_input_valid : bool

# Available tower patterns
var AvailableTowers : Array[towercall] = []

# Tower preview instance
var tower_preview : Node3D

var ammo_in_dart_mag : int
var dart_mags : int

var SPEED = 4.5
var base_speed : float
var speed : float

const JUMP_VELOCITY = 4.5
const sensitivity = 0.01

var debugmode : bool

# Aerial camera drag speed
const DRAG_SPEED = 0.05

# RTS camera movement speed
const CAMERA_SPEED = 20.0

# Camera movement input vector (RTS mode)
var camera_input_dir : Vector2 = Vector2.ZERO

var fallheight : int

# Top-down mode state
var top_view_enabled : bool = false

# Mouse drag state
var dragging : bool = false

# Stored camera transform (FPS mode)
var normal_camera_position : Vector3
var normal_camera_rotation : Vector3

var burning_cooldown : int

var is_reloading : bool


func _ready() -> void:
	stam = 1200
	hp = 100

	dart_mags = 10
	ammo_in_dart_mag = 1
	reloadbar.visible = 0

	debugmode = false

	is_reloading = false
	burning_cooldown = 60
	fallheight = 0

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Save normal FPS camera transform
	normal_camera_position = Camera.position
	normal_camera_rotation = Camera.rotation

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseMotion and not top_view_enabled:
		rotate_y(-event.relative.x * sensitivity)
		Camera.rotate_x(-event.relative.y * sensitivity)
		Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	
	if event is InputEventMouseMotion and top_view_enabled :
		Camera.position.x += event.relative.x / 5
		Camera.position.z += event.relative.y / 5

func _physics_process(delta: float) -> void:

	reload(3, 1.0)

	tower_input_validity()

	UI_update()

	debug_mode()

	base_speed = SPEED

	# Status effects system
	if burning_cooldown > 0:
		burning_cooldown -= 1

	effects_application()

	# Top-down mode logic
	if top_view_enabled:

		top_view_processes(delta)

		return

	sprint()

	aim()

	gravity(delta)

	move()

func _input(event):

	# Toggle top view mode
	if event.is_action_pressed("Toggle.TopView"):
		toggle_top_view()

	# Top view controls
	if top_view_enabled:

		# Place tower
		if event is InputEventMouseButton:
			
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var pos = get_mouse_world_position()
				if pos:
					place_tower(pos)

			# Drag camera with right mouse button
			if event.button_index == MOUSE_BUTTON_RIGHT:
				dragging = event.pressed

		if event is InputEventMouseMotion and dragging:
			Camera.global_position.x -= event.relative.x * DRAG_SPEED
			Camera.global_position.z -= event.relative.y * DRAG_SPEED
			
		return

	# Shooting
	if event.is_action_pressed("shoot") and ammo_in_dart_mag:
		shoot()
		ammo_in_dart_mag -= 1

	

	# Tower input system
	if TowerInput.size() > 0:
		for tower in AvailableTowers:
			if TowerInput.size() <= tower.input.size():
				if TowerInput[-1] != tower.input[TowerInput.size() - 1]:
					is_tower_input_valid = false
	if not is_tower_input_valid :
		TowerInput.clear()

func toggle_top_view():

	top_view_enabled = !top_view_enabled

	if top_view_enabled:

		Camera.global_position = global_position + Vector3(0, 15, 0)
		Camera.rotation_degrees = Vector3(-90, 0, 0)
		
		if TowerPlaceholders.size() > 0:
			tower_preview = TowerPlaceholders[selected_tower_index].instantiate()
			get_tree().current_scene.add_child(tower_preview)

	else:

		dragging = false

		if tower_preview:
			tower_preview.queue_free()
			tower_preview = null

		Camera.position = normal_camera_position
		Camera.rotation = normal_camera_rotation

func get_mouse_world_position():

	var mouse_pos = get_viewport().get_mouse_position()

	var from = Camera.project_ray_origin(mouse_pos)
	var to = from + Camera.project_ray_normal(mouse_pos) * 1000

	var space = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(from, to)

	if tower_preview:
		query.exclude = [tower_preview]

	var result = space.intersect_ray(query)

	if result:
		return result.position

	return null

func place_tower(pos: Vector3):

	if TowerPlaceholders.size() == 0:
		return

	var tower = TowerPlaceholders[selected_tower_index].instantiate()
	get_tree().current_scene.add_child(tower)

	tower.global_position = pos

func shoot():

	var bullet = Bullet.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_transform.origin = BulletSpawnPoint.global_transform.origin

	var shoot_direction = -Camera.global_transform.basis.z
	bullet.look_at(bullet.global_position + shoot_direction, Vector3.UP)
	bullet.direction = shoot_direction

func append_to_tower_input(key: String, input: String) :
	if Input.is_action_just_pressed(key) :
			TowerInput.append(input)
			for tower in AvailableTowers :
				if TowerInput[TowerInput.size() - 1] != tower.input[TowerInput.size() - 1] :
					is_tower_input_valid = false

func reload(mag_size: int, reload__time: float) :
	if Input.is_action_just_pressed("Reload") and not top_view_enabled and not is_reloading :
		reloadbar.visible = 1
		is_reloading = 1
		reload_time.start(reload__time)
		await reload_time.timeout
		dart_mags -= 1
		ammo_in_dart_mag = mag_size
		reloadbar.visible = 0
		is_reloading = 0

func sprint() :
	if Input.is_action_pressed("Move.Sprint") and is_on_floor() and stam > 0:
		speed = 1.35 * base_speed
		stam -= 2
	else:
		speed = base_speed
		if stam < 1200:
			stam += 1

func tower_input_validity() :
	if is_tower_input_valid :
		for tower in AvailableTowers :
			selected_tower_index = tower.index

func UI_update() :
	Mags.text = "N° of Mags : " + str(dart_mags)
	Ammo.text = "Ammo in Mag : " + str(ammo_in_dart_mag)
	hpbar.value = hp
	stambar.value = stam
	reloadbar.value = max(reload_time.time_left, 0)

func debug_mode() :
	if Input.is_action_just_pressed("Debug"):
		debugmode = !debugmode

	# Debug speed control
	if debugmode and Input.is_action_just_pressed("Move.Forward"):
		SPEED *= 2
	if debugmode and Input.is_action_just_pressed("Move.Back"):
		SPEED /= 2

func effects_application() :
	for effect in Effects.duplicate():

		if effect.duration <= 0:
			Effects.erase(effect)

		# Burning damage over time
		if effect.name == "burning" and burning_cooldown == 0:
			hp -= 4 + 1 * effect.magnitude

		if burning_cooldown == 0:
			burning_cooldown = 60

		# Slow effect
		if effect.name == "slow":
			base_speed = (0.95 - 0.05 * effect.magnitude) * SPEED

func top_view_processes(delta: float) :
	# Move tower preview to mouse position
		if tower_preview:
			var pos = get_mouse_world_position()
			if pos:
				tower_preview.global_position = pos

		# RTS camera movement (WASD)
		var cam_dir = camera_input_dir.normalized()
		Camera.global_position.x += cam_dir.x * CAMERA_SPEED * delta
		Camera.global_position.z += cam_dir.y * CAMERA_SPEED * delta
		
		append_to_tower_input("Move.Forward", "U")
		append_to_tower_input("Move.Back", "D")
		append_to_tower_input("Move.Right", "R")
		append_to_tower_input("Move.Left", "L")

func aim() :
	if Input.is_action_pressed("Aim"):
		speed = 0.45 * base_speed

func gravity(delta: float) :
	if not is_on_floor():
		fallheight += 1
		velocity += get_gravity() * delta

func fall() :
	if is_on_floor():
		if fallheight > 100:
			hp -= int(0.2 * fallheight)
		fallheight = 0

func move() : 
	var input_dir = Input.get_vector("Move.Left", "Move.Right", "Move.Forward", "Move.Back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	fall()

	move_and_slide()
