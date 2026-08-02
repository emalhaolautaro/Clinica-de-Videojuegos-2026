extends Marker2D

const SIMPLE_ROBOT := preload("res://enemies/simpleRobot.tscn")

@onready var player: CharacterBody2D = $"../Player"
@onready var timer: Timer = $Timer


func _ready() -> void:
	spawn_enemy.call_deferred()
	timer.timeout.connect(spawn_enemy)


func spawn_enemy() -> void:
	if not is_instance_valid(player):
		return

	var enemy = SIMPLE_ROBOT.instantiate()

	enemy.player = player
	enemy.global_position = global_position

	get_tree().current_scene.add_child(enemy)
