extends Marker3D

@onready var enemy : PackedScene = load("res://Scenes/Enemy.tscn")

@export var difficulty : int

var wave : int
var cooldown : int
var enemies_spawned : int
var enemies_to_spawn : int
var enemies_alive := 0
var max_waves := 10

func _ready():
	wave = 1
	enemies_spawned = 0
	enemies_to_spawn = 5

func _physics_process(_delta: float) -> void:
	if cooldown > 0:
		cooldown -= 1
		return
	
	if enemies_spawned < enemies_to_spawn:
		spawn_enemy()
		cooldown = 30
		return
	
	if enemies_alive > 0:
		return
	
	if wave >= max_waves:
		victory()
		return
	
	cooldown = 3600 - wave * 20 - difficulty * 50
	
	if cooldown < 1200:
		cooldown = 1200
	
	wave += 1
	enemies_spawned = 0
	enemies_to_spawn = 4 + wave + difficulty + 4

func spawn_enemy():
	var Enemy = enemy.instantiate()
	get_parent().add_child(Enemy)
	
	Enemy.global_position = global_position
	
	enemies_spawned += 1
	enemies_alive += 1
	
	Enemy.connect("tree_exited", Callable(self, "_on_enemy_died"))

func _on_enemy_died():
	enemies_alive -= 1
	
func victory():
	get_tree().change_scene_to_file("res://Victory.tscn")
