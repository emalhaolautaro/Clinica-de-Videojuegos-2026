extends Node2D

@onready var player: CharacterBody2D = $Player

var batteries_remaining := 0
var game_finished := false


func _ready() -> void:
	var batteries := get_tree().get_nodes_in_group("batteries")
	batteries_remaining = batteries.size()

	print("Baterías encontradas: ", batteries_remaining)

	for battery in batteries:
		print("Conectando batería: ", battery.name)
		battery.destroyed.connect(_on_battery_destroyed)

	player.died.connect(_on_player_died)


func _on_battery_destroyed() -> void:
	if game_finished:
		return

	batteries_remaining -= 1
	print("Batería destruida. Quedan: ", batteries_remaining)

	if batteries_remaining <= 0:
		finish_level(true)


func _on_player_died() -> void:
	if game_finished:
		return

	finish_level(false)


func finish_level(victory: bool) -> void:
	game_finished = true
	print("Terminó el nivel. Victoria: ", victory)
	GameManager.finish_game(victory)
