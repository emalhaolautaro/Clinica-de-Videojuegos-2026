extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD


var batteries_remaining := 0
var game_finished := false


func _ready() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if "player" in enemy:
			enemy.player = player

	var batteries := get_tree().get_nodes_in_group("batteries")
	batteries_remaining = batteries.size()

	print("Baterías encontradas: ", batteries_remaining)

	for battery in batteries:
		print("Conectando batería: ", battery.name)
		battery.destroyed.connect(_on_battery_destroyed)

	player.died.connect(_on_player_died)
	
	if hud:
		player.max_health_changed.connect(hud.update_max_health)
		player.health_changed.connect(hud.update_health)
		hud.update_max_health(player.max_health)
		hud.update_health(player.health)
		
		player.max_energy_changed.connect(hud.update_max_energy)
		player.energy_changed.connect(hud.update_energy)
		hud.update_max_energy(player.max_energy)
		hud.update_energy(player.energy)


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
