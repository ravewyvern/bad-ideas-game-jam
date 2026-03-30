extends CharacterBody3D

#region export vars

@export var stam : int
@onready var hp : int = get_parent().get_node("Box").hp
@export var Bullet : PackedScene
@export var BulletSpawnPoint : Node3D

# Tower list (5 towers)
@export var TowerPlaceholders : Array[PackedScene] = [null, ]
var selected_tower_index : int = 0

#endregion

#region child nodes

@onready var Camera = $Head/Camera3D
@onready var hpbar = $HpBar
@onready var stambar = $StamBar
@onready var Mags = $Mags
@onready var Ammo = $AmmoInMag
@onready var reloadbar = $ReloadBar
@onready var reload_time = $Timer
@onready var sound = $AudioStreamPlayer

#endregion

#region classes

class StatusEffect:
	var name : String
	var duration : float
	var magnitude : int

class towercall:
	var input : Array[String] = []
	var index : int = 0
	var is_unlocked : bool = 0
	func _init(i1 : Array[String], i2 : int, u : bool) :
		input = i1
		index = i2
		is_unlocked = u

#endregion

#region general variables

var shoot_cooldown : int = 0

# Active status effects list
var Effects : Array[StatusEffect] = []

# Tower input buffer
var TowerInput : Array[String] = []
var is_tower_input_valid : bool

# Available tower patterns
var archer_tower = towercall.new(["U", "D", "R", "L"], 1, 1)
var AvailableTowers : Array[towercall] = [archer_tower]

# Tower preview instance
var tower_preview : Node3D

var ammo_in_dart_mag : int
var dart_mags : int

var SPEED = 4.5
var base_speed : float
var speed : float

var debugmode : bool

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

# Click detection area (manual XY/XZ check)
var target_click_position : Vector3 = Vector3(0, 0, 0)
var click_area_size : Vector2 = Vector2(2, 2) # width (X) and depth (Z)

# Clickable positions (only X and Z are relevant)
var target_positions : Array[Vector3] = [
	Vector3(28.051, 0, 160.478),
	Vector3(-31.911, 0, 160.478),
	Vector3(28.051, 0, 129.89),
	Vector3(-31.255, 0, 129.89),
	Vector3(2.138, 0, 106.671),
	Vector3(28.051, 0, 71.034),
	Vector3(28.051, 0, 40.445),
	Vector3(-31.911, 0, 72.196),
	Vector3(-31.255, 0, 41.608)
]

#endregion

#region constants

const JUMP_VELOCITY = 4.5
const sensitivity = 0.01

# Aerial camera drag speed
const DRAG_SPEED = 0.05

# RTS camera movement speed
const CAMERA_SPEED = 20.0

#endregion

#region Engine functions

func _ready() -> void:
	
	stam = 1200
	hp = 100

	dart_mags = 10
	ammo_in_dart_mag = 5
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
		Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	if event is InputEventMouseMotion and top_view_enabled :
		Camera.position.x += event.relative.x / 5
		Camera.position.z += event.relative.y / 5

func _physics_process(delta: float) -> void:

	if Input.is_action_pressed("shoot") and ammo_in_dart_mag:
		shoot()

	reload(5, 1.0)

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
					var clicked_index = get_clicked_area_index(pos)
					
					if clicked_index != -1:
						var center_pos = target_positions[clicked_index]
						if is_click_in_range(pos, center_pos.x - 2, center_pos.x + 2, center_pos.z - 2, center_pos.z + 2):
							print("Clicked inside area index: ", clicked_index)
							on_specific_area_clicked(clicked_index)

			# Drag camera with right mouse button
			if event.button_index == MOUSE_BUTTON_RIGHT:
				dragging = event.pressed

		if event is InputEventMouseMotion and dragging:
			Camera.global_position.x -= event.relative.x * DRAG_SPEED
			Camera.global_position.z -= event.relative.y * DRAG_SPEED
			
		return

	# Shooting

	

	# Tower input system
	if TowerInput.size() > 0:
		for tower in AvailableTowers:
			if TowerInput.size() <= tower.input.size():
				if TowerInput[-1] != tower.input[TowerInput.size() - 1]:
					is_tower_input_valid = false
	if not is_tower_input_valid :
		TowerInput.clear()

#endregion

#region Code functions

#region player input functions

func shoot():
	if not is_reloading and not shoot_cooldown :
		ammo_in_dart_mag -= 1
		sound.play()
		var bullet = Bullet.instantiate()
		get_tree().current_scene.add_child(bullet)

		bullet.global_transform.origin = BulletSpawnPoint.global_transform.origin

		var shoot_direction = -Camera.global_transform.basis.z
		bullet.look_at(bullet.global_position + shoot_direction, Vector3.UP)
		bullet.direction = shoot_direction
		shoot_cooldown = 20
		return
	shoot_cooldown -= 1

func append_to_tower_input(key: String, input: String) :
	if Input.is_action_just_pressed(key) :
			TowerInput.append(input)
			for tower in AvailableTowers :
				if tower.input.size() < TowerInput.size() :
					is_tower_input_valid = false
					break
				if TowerInput[TowerInput.size() - 1] != tower.input[TowerInput.size() - 1] :
					is_tower_input_valid = false
					break
	if not is_tower_input_valid :
		TowerInput.clear()
		is_tower_input_valid = true

func sprint() :
	if Input.is_action_pressed("Move.Sprint") and is_on_floor() and stam > 0:
		speed = 1.35 * base_speed
		stam -= 2
	else:
		speed = base_speed
		if stam < 1200:
			stam += 1

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

func move() : 
	var input_dir = Input.get_vector("Move.Left", "Move.Right", "Move.Forward", "Move.Back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	fall()

	move_and_slide()

func aim() :
	if Input.is_action_pressed("Aim"):
		speed = 0.45 * base_speed

func debug_mode() :
	if Input.is_action_just_pressed("Debug"):
		debugmode = !debugmode

	# Debug speed control
	if debugmode and Input.is_action_just_pressed("Move.Forward"):
		SPEED *= 2
	if debugmode and Input.is_action_just_pressed("Move.Back"):
		SPEED /= 2

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
		
# Check if a world position is inside a defined area
func is_click_inside_area(click_pos: Vector3) -> bool:
	
	var min_x = target_click_position.x
	var max_x = target_click_position.x + click_area_size.x
	
	var min_z = target_click_position.z
	var max_z = target_click_position.z + click_area_size.y
	
	if click_pos.x > min_x and click_pos.x < max_x \
	and click_pos.z > min_z and click_pos.z < max_z:
		return true
	
	return false


# Action executed when clicking the target area
func on_target_clicked():

	var tower = TowerPlaceholders[selected_tower_index].instantiate()
	get_tree().current_scene.add_child(tower)
	tower.global_position = target_click_position

#endregion

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
	
# Check if click is inside a custom rectangular range
func is_click_in_range(click_pos: Vector3, min_x: float, max_x: float, min_z: float, max_z: float) -> bool:
	if click_pos.x >= min_x and click_pos.x <= max_x \
	and click_pos.z >= min_z and click_pos.z <= max_z:
		return true
	return false
	
# Returns the index of the clicked area, or -1 if none
func get_clicked_area_index(click_pos: Vector3) -> int:
	
	for i in range(target_positions.size()):
		
		var pos = target_positions[i]
		
		var min_x = pos.x - click_area_size.x / 2
		var max_x = pos.x + click_area_size.x / 2

		var min_z = pos.z - click_area_size.y / 2
		var max_z = pos.z + click_area_size.y / 2
		
		if click_pos.x > min_x and click_pos.x < max_x \
		and click_pos.z > min_z and click_pos.z < max_z:
			return i
	
	return -1
	
# Executes action based on which area was clicked
func on_specific_area_clicked(index: int):
	
	print("Something happened on area: ", index)
	
	var tower = TowerPlaceholders[selected_tower_index].instantiate()
	get_tree().current_scene.add_child(tower)
	
	tower.global_position = target_positions[index]

func place_tower(pos: Vector3):

	if TowerPlaceholders.size() == 0:
		return

	var tower = TowerPlaceholders[selected_tower_index].instantiate()
	get_tree().current_scene.add_child(tower)

	tower.global_position = pos

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
		print(TowerInput)

func gravity(delta: float) :
	if not is_on_floor():
		fallheight += 1
		velocity += get_gravity() * delta

func fall() :
	if is_on_floor():
		if fallheight > 100:
			hp -= int(0.2 * fallheight)
		fallheight = 0


#endregion
