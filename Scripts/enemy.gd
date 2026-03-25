extends CharacterBody3D

@export var health = 50

# movement speed
@export var speed = 3.0

# distance required to consider the point reached
@export var point_reach_distance = 2.0

# node that contains the path markers
@export var Path_A : Node3D

@onready var box = get_parent().get_node("Box")

# path points the enemy will follow
var PathPoints : Array[Marker3D] = []

# current point in the path
var current_point : int = 0


func _ready():

	# define Path_A
	Path_A = get_parent().get_node("Enemy_Path")

	# Get all markers inside Path_A
	for child in Path_A.get_children():
		if child is Marker3D:
			PathPoints.append(child)

	# Spawn enemy at the first marker
	if PathPoints.size() > 0:
		global_position = PathPoints[0].global_position


func _physics_process(delta):

	# Add gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Follow predefined path points
	if PathPoints.size() > 0:
		
		# Get current target point
		var target = PathPoints[current_point].global_position
		
		# Calculate direction to the point
		var direction = (target - global_position).normalized()
		
		# Move toward the point
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# Check if the enemy reached the point
		if global_position.distance_to(target) < point_reach_distance:
			
			# Move to next point
			current_point += 1
			
			# Stop at the last point
			if current_point >= PathPoints.size():
				current_point = PathPoints.size() - 1

	move_and_slide()


# Receive damage based on bullet "damage" var.
func take_damage(amount):
	health -= amount
	print("Damage:", amount)

	if health <= 0:
		die()


func die():
	queue_free()

func reach_box() :
	velocity.y = 6
