extends Marker2D


# ============================================================
# ESCENA DEL ENEMIGO
# ============================================================
const SIMPLE_ROBOT := preload("res://enemies/simpleRobot.tscn")

# ============================================================
# NODOS
# ============================================================
@onready var player: CharacterBody2D = $"../../Player"
@onready var timer: Timer = $Timer


# ============================================================
# CONFIGURACIÓN (se ajusta distinto por cada SpawnPoint)
# ============================================================
@export var max_enemies := 6
@export var max_nearby_enemies := 2
@export var nearby_radius := 150.0

# false (default) → el chequeo de "cercanos" mira TODOS los
#                    enemigos de la escena, sin importar de
#                    qué spawner salieron. Útil en zonas
#                    grandes y conectadas, como el piso, donde
#                    interesa que la densidad general quede
#                    bien distribuida.
#
# true            → el chequeo de "cercanos" solo mira los
#                    enemigos que ESTE spawner generó. Útil en
#                    plataformas chicas y aisladas, donde no
#                    tiene sentido que un spawner se frene
#                    porque hay enemigos cerca que en realidad
#                    pertenecen a OTRA plataforma (por ejemplo,
#                    una plataforma justo debajo de otra).
@export var count_own_enemies_only := false

# Se le pasa a cada enemigo instanciado. Si es false, el
# enemigo va a patrullar pero nunca va a perseguir al jugador
# (pensado para plataformas chicas, donde un enemigo persiguiendo
# se vuelve un estorbo para poder subir).
@export var spawned_can_chase := true


# ============================================================
# ESTADO INTERNO
# ============================================================

# Lista de los enemigos que ESTE spawner generó. Cada
# SpawnPoint tiene su propia instancia de este array (no se
# comparte entre spawners), porque cada uno corre su propia
# copia independiente del script.
var _spawned_enemies: Array[Node] = []


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	spawn_enemy.call_deferred()
	timer.timeout.connect(spawn_enemy)


# ============================================================
# SPAWN
# ============================================================

func spawn_enemy() -> void:
	_spawned_enemies = _spawned_enemies.filter(is_instance_valid)

	if _spawned_enemies.size() >= max_enemies:
		return

	var enemies_to_check := (
		_spawned_enemies
		if count_own_enemies_only
		else get_tree().get_nodes_in_group("enemies")
	)

	var nearby_enemies_count := 0
	for e in enemies_to_check:
		if e.global_position.distance_to(global_position) <= nearby_radius:
			nearby_enemies_count += 1

	if nearby_enemies_count >= max_nearby_enemies:
		return

	var enemy = SIMPLE_ROBOT.instantiate()
	enemy.player = player
	enemy.can_chase = spawned_can_chase
	enemy.global_position = global_position
	get_tree().current_scene.add_child(enemy)

	_spawned_enemies.append(enemy)
