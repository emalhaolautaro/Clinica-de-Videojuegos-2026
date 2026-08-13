extends Marker2D

const SIMPLE_ROBOT := preload("res://enemies/simpleRobot.tscn")

@onready var player: CharacterBody2D = $"../../Player"
@onready var timer: Timer = $Timer
@export var max_enemies := 6
@export var max_nearby_enemies := 2
@export var nearby_radius := 150.0


func _ready() -> void:
	spawn_enemy.call_deferred()
	timer.timeout.connect(spawn_enemy)


func spawn_enemy() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")

	if enemies.size() >= max_enemies:
		return

	var nearby_enemies_count := 0
	for e in enemies:
		if e.global_position.distance_to(global_position) <= nearby_radius:
			nearby_enemies_count += 1
			
	if nearby_enemies_count >= max_nearby_enemies:
		return

	var enemy = SIMPLE_ROBOT.instantiate()
	enemy.player = player
	enemy.global_position = global_position
	get_tree().current_scene.add_child(enemy)
