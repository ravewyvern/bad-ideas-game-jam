extends CharacterBody3D

@export var stam : int
@export var hp : int = 100
@export var Bullet : PackedScene
@export var BulletSpawnPoint : Node3D

# placeholder tower scene
@export var TowerPlaceholder : PackedScene

@onready var Camera = $Head/Camera3D
@onready var hpbar = $HpBar
@onready var stambar = $StamBar
@onready var Mags = $Mags
@onready var Ammo = $AmmoInMag
@onready var reload = $ReloadBar

class StatusEffect :
	var name : String
	var duration : float
	var magnitude : int
	
class towercall :
	var input : Array[String]

var Effects : Array[StatusEffect]

var TowerInput : Array[String]
var AvailableTowers : Array[towercall]

# preview tower instance
var tower_preview : Node3D

var ammo_in_dart_mag : int
var dart_mags : int

var SPEED = 4.5
var base_speed : float
var speed : float
const JUMP_VELOCITY = 4.5
const sensitivity = 0.01

var debugmode : bool

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
var burning_cooldown : int

var reload_time : int
var is_reloading : bool

func _ready() -> void:
	stam = 1200
	hp = 100
	
	
	dart_mags = 10
	ammo_in_dart_mag = 1
	
	debugmode = false
	
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
	
	# sets mag count and ammo in mag count 
	Mags.text = "N° of Mags : " + str(dart_mags)
	Ammo.text = "Ammo in Mag : " + str(ammo_in_dart_mag)
	
	# enters and exits debug mode
	if Input.is_action_just_pressed("Debug") :
		if not debugmode :
			debugmode = true
			print("debugmode entered")
		else :
			debugmode = false
			print("debugmode exited")
	
	if is_reloading :
		reload_time -= 1
	if reload_time == 0 :
		reload.visible = false
		is_reloading = false
		reload_time = -1
		dart_mags -= 1
		ammo_in_dart_mag = 1
	
	
	# debug mode actions
	if debugmode and Input.is_action_just_pressed("Move.Forward") :
		SPEED *= 2
	if debugmode and Input.is_action_just_pressed("Move.Back") :
		SPEED /= 2
	
	# sets hp bar to hp value and stam bar to stam value
	hpbar.value = hp
	stambar.value = stam
	
	reload.value = reload_time
	
	base_speed = SPEED
	
	# applies active status effects
	burning_cooldown -= 1
	for effect in Effects :
		if effect.duration <= 0 :
			Effects.erase(effect)
		if effect.name == "burning" and burning_cooldown == 0: 
			hp -= 4 + 1 * effect.magnitude
		if burning_cooldown == 0 :
			burning_cooldown = 60
		if effect.name == "slow" :
			base_speed = (0.95 - 0.05 * effect.magnitude) * SPEED
	
	# disables player movement when in aerial view
	if top_view_enabled:
		
		# moves preview tower to mouse position
		if tower_preview:
			var pos = get_mouse_world_position()
			if pos:
				tower_preview.global_position = pos
		
		return
	
	
	
	# Sprints on spacebar held
	if Input.is_action_pressed("Move.Jump") and is_on_floor() and stam > 0:
		speed = 1.35 * base_speed
		stam -= 2
	else :
		speed = base_speed
		if stam < 1200 :
			stam += 1
	
	if Input.is_action_pressed("Aim") :
		speed = 0.45 * base_speed
	
	# Add the gravity and counts fall length to determine fall damage
	if not is_on_floor():
		fallheight += 1
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Move.Left", "Move.Right", "Move.Forward", "Move.Back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
	
	# applies fall damage
	if is_on_floor() :
		if fallheight > 100 :
			@warning_ignore("narrowing_conversion")
			hp -= 0.2 * fallheight
		fallheight = 0

	move_and_slide()
	
	print(str(reload_time) + str(is_reloading))


func _input(event):
	
	# toggles aerial view
	if event.is_action_pressed("Toggle.TopView"):
		toggle_top_view()
	
	# handles aerial camera movement
	if top_view_enabled:
		
		# starts dragging when mouse button is pressed
		if event is InputEventMouseButton:
			
			# places tower on left click
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				
				var pos = get_mouse_world_position()
				
				if pos:
					place_tower(pos)
			
			# enables camera drag with right mouse button
			if event.button_index == MOUSE_BUTTON_RIGHT:
				dragging = event.pressed
		
		# moves camera while dragging (only on map plane X/Z)
		if event is InputEventMouseMotion and dragging:
			
			# moves camera left/right
			Camera.global_position.x -= event.relative.x * DRAG_SPEED
			
			# moves camera forward/back on the map
			Camera.global_position.z -= event.relative.y * DRAG_SPEED
		
		return
	
	if event.is_action_pressed("shoot") and ammo_in_dart_mag:
		shoot()
		ammo_in_dart_mag -= 1
	
	if event.is_action_just_pressed("Reload") and dart_mags and not is_reloading :
		reload_time = 60
		is_reloading = true
		reload.visible = true
		
	if event.is_action_pressed("Move.Forward") and top_view_enabled :
		TowerInput.append("U")
		for tower in AvailableTowers :
			if not TowerInput[TowerInput.size()-1] == tower.input[TowerInput.size()-1] :
				TowerInput.clear()
	if event.is_action_pressed("Move.Back") and top_view_enabled :
		TowerInput.append("D")
		for tower in AvailableTowers :
			if not TowerInput[TowerInput.size()-1] == tower.input[TowerInput.size()-1] :
				TowerInput.clear()
	if event.is_action_pressed("Move.Right") and top_view_enabled :
		TowerInput.append("R")
		for tower in AvailableTowers :
			if not TowerInput[TowerInput.size()-1] == tower.input[TowerInput.size()-1] :
				TowerInput.clear()
	if event.is_action_pressed("Move.Left") and top_view_enabled :
		TowerInput.append("L")
		for tower in AvailableTowers :
			if not TowerInput[TowerInput.size()-1] == tower.input[TowerInput.size()-1] :
				TowerInput.clear()


func toggle_top_view():
	
	# toggles aerial camera mode
	top_view_enabled = !top_view_enabled
	
	if top_view_enabled:
		
		# moves camera above the player
		Camera.global_position = global_position + Vector3(0, 15, 0)
		
		# rotates camera to look straight down
		Camera.rotation_degrees = Vector3(-90, 0, 0)
		
		# releases mouse so player can interact with map
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		# creates tower preview
		if TowerPlaceholder:
			tower_preview = TowerPlaceholder.instantiate()
			get_tree().current_scene.add_child(tower_preview)
		
	else:
		
		# stops dragging
		dragging = false
		
		# removes preview tower
		if tower_preview:
			tower_preview.queue_free()
			tower_preview = null
		
		# restores normal camera transform
		Camera.position = normal_camera_position
		Camera.rotation = normal_camera_rotation
		
		# captures mouse again for FPS control
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# finds the world position under the mouse using a raycast
func get_mouse_world_position():
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	var from = Camera.project_ray_origin(mouse_pos)
	var to = from + Camera.project_ray_normal(mouse_pos) * 1000
	
	var space = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	# ignores preview tower collision
	if tower_preview:
		query.exclude = [tower_preview]
	
	var result = space.intersect_ray(query)
	
	if result:
		return result.position
	
	return null


# places a tower at the given position
func place_tower(pos: Vector3):
	
	var tower = TowerPlaceholder.instantiate()
	get_tree().current_scene.add_child(tower)
	
	tower.global_position = pos


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
