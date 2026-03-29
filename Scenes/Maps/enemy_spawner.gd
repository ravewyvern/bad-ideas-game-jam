extends Marker3D

# Enemy scene to instantiate
@export var enemy_scene : PackedScene

# Difficulty setting
@export var difficulty : int

# Wave and spawn control
var wave : int
var cooldown : int
var enemies_spawned : int
var enemies_to_spawn : int
var enemies_alive := 0
var max_waves := 10


func _ready():
	wave = 1
	enemies_spawned = 0
	enemies_to_spawn = 10


func _physics_process(_delta: float) -> void:
	# Handle spawn cooldown
	if cooldown > 0:
		cooldown -= 1
		return

	# Spawn enemies until reaching the target for this wave
	if enemies_spawned < enemies_to_spawn:
		spawn_enemy()
		cooldown = 30
		return

	# Wait until all enemies are dead before starting next wave
	if enemies_alive > 0:
		return

	# Check for victory condition
	if wave >= max_waves:
		victory()
		return

	# Calculate cooldown for next wave
	cooldown = 3600 - wave * 20 - difficulty * 50
	if cooldown < 1200:
		cooldown = 1200

	# Prepare next wave
	wave += 1
	enemies_spawned = 0
	enemies_to_spawn = 4 + wave + difficulty + 4


func spawn_enemy():
	if not enemy_scene:
		return # Safety check

	var Enemy = enemy_scene.instantiate()
	get_parent().add_child(Enemy)

	# Spawn at spawner position
	Enemy.global_position = global_position

	# Update counters
	enemies_spawned += 1
	enemies_alive += 1

	# Detect when enemy dies
	Enemy.connect("tree_exited", Callable(self, "_on_enemy_died"))


func _on_enemy_died():
	enemies_alive -= 1


func victory():
	get_tree().change_scene_to_file("res://Scenes/Menus/Victory.tscn")
