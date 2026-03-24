extends Marker3D

@onready var enemy : PackedScene = load("res://Scenes/Enemy.tscn")

@export var difficulty : int

var wave : int
var cooldown : int
var enemies_spawned : int
var enemies_to_spawn : int

func _ready() :
	wave = 1

func _physics_process(_delta: float) -> void:
	if cooldown :
		cooldown -= 1
		return
	if enemies_spawned < enemies_to_spawn :
		spawn_enemy()
		cooldown = 30
		return
	if enemies_spawned == enemies_to_spawn :
		cooldown = 3600 - wave * 20 - difficulty * 50
		if cooldown < 1200 :
			cooldown = 1200
		wave += 1
		enemies_spawned = 0
		enemies_to_spawn = 4 + wave + difficulty + 4

func spawn_enemy() :
	var Enemy = enemy.instantiate()
	get_parent().add_child(Enemy)
