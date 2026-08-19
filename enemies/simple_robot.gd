extends CharacterBody2D


# ============================================================
# SHADERS
# ============================================================

const DISSOLVE_SHADER: Shader = preload("res://enemies/dissolve.gdshader")
const DEATH_SHADER: Shader = preload("res://enemies/death_flash.gdshader")
const PIXELATE_SHADER: Shader = preload("res://enemies/pixelate_death.gdshader")


# ============================================================
# ESTADOS
# ============================================================

enum State {
	PATROL,
	CHASE
}


# ============================================================
# CONFIGURACIÓN
# ============================================================

@export var speed: float = 40.0
@export var chase_distance: float = 180.0
@export var max_vertical_distance: float = 40.0

@export var max_health: int = 3
@export var dissolve_duration: float = 0.8

@export var contact_damage: int = 1
@export var damage_tick_interval: float = 1.0


# Spawn
@export var spawn_duration: float = 0.6
@export var spawn_light_energy: float = 2.5


# Retroceso al aparecer
@export var spawn_knockback: float = 90.0
@export var spawn_jump: float = -180.0


# Retroceso al recibir daño
@export var damage_knockback: float = 100.0
@export var damage_jump: float = -100.0


# Retroceso al golpear al jugador
@export var contact_knockback: float = 80.0
@export var contact_jump: float = -120.0


# Rayo eléctrico
@export var electric_duration: float = 0.15


# ============================================================
# VARIABLES
# ============================================================

var player: CharacterBody2D

var direction: float = 1.0
var state: State = State.PATROL

var health: int

var is_dying: bool = false
var is_spawning: bool = true

var _bodies_in_damage_area: Array[Node2D] = []
var _damage_tick_timer: Timer


# ============================================================
# NODOS
# ============================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var spawn_light: PointLight2D = $SpawnLight
@onready var electric_flash: Line2D = $ElectricFlash


# ============================================================
# GRAVEDAD
# ============================================================

var gravity: float = float(
	ProjectSettings.get_setting("physics/2d/default_gravity")
)


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	health = max_health

	_setup_dissolve_shader()

	# Dirección inicial aleatoria
	if randf() < 0.5:
		direction = -1.0
	else:
		direction = 1.0

	update_floor_detector()


	# --------------------------------------------------------
	# Timer de daño por contacto
	# --------------------------------------------------------

	_damage_tick_timer = Timer.new()
	_damage_tick_timer.wait_time = damage_tick_interval
	_damage_tick_timer.timeout.connect(_on_damage_tick_timeout)
	add_child(_damage_tick_timer)


	# --------------------------------------------------------
	# DamageArea
	# --------------------------------------------------------

	var damage_area: Area2D = $DamageArea

	if damage_area:
		damage_area.body_exited.connect(
			_on_damage_area_body_exited
		)


	# --------------------------------------------------------
	# Configuración del rayo
	# --------------------------------------------------------

	electric_flash.visible = false
	electric_flash.width = 1.0
	electric_flash.default_color = Color(
		0.8,
		0.95,
		1.0
	)


	# --------------------------------------------------------
	# Spawn
	# --------------------------------------------------------

	_start_spawn_effect()


# ============================================================
# SHADER DE MUERTE
# ============================================================

func _setup_dissolve_shader() -> void:

	# Para el efecto de DISSOLVE
	#
	#if not sprite:
	#	return
	#
	#var shader_material := ShaderMaterial.new()
	#shader_material.shader = DISSOLVE_SHADER
	#
	#var noise := FastNoiseLite.new()
	#noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	#noise.frequency = 0.05
	#
	#var noise_tex := NoiseTexture2D.new()
	#noise_tex.noise = noise
	#noise_tex.width = 256
	#noise_tex.height = 256
	#
	#shader_material.set_shader_parameter(
	#	"noise_texture",
	#	noise_tex
	#)
	#
	#shader_material.set_shader_parameter(
	#	"dissolve_amount",
	#	0.0
	#)
	#
	#sprite.material = shader_material


	# Efecto de flash + fade

	if not sprite:
		return

	var shader_material := ShaderMaterial.new()
	shader_material.shader = DEATH_SHADER

	sprite.material = shader_material


# ============================================================
# PHYSICS PROCESS
# ============================================================

func _physics_process(delta: float) -> void:

	# La gravedad sigue funcionando durante el spawn
	if not is_on_floor():
		velocity.y += gravity * delta


	# Durante el spawn no ejecutamos la IA
	if is_spawning:
		move_and_slide()
		return


	# IA normal
	update_state()

	match state:
		State.PATROL:
			patrol()

		State.CHASE:
			chase_player()

	move_and_slide()


# ============================================================
# SPAWN-IN
# ============================================================

func _start_spawn_effect() -> void:

	is_spawning = true


	# --------------------------------------------------------
	# Robot invisible
	# --------------------------------------------------------

	sprite.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)


	# --------------------------------------------------------
	# Luz apagada
	# --------------------------------------------------------

	spawn_light.energy = 0.0


	# --------------------------------------------------------
	# Rayo inicial
	# --------------------------------------------------------

	_show_electric_flash()


	# --------------------------------------------------------
	# Fade del robot
	# --------------------------------------------------------

	var sprite_tween := create_tween()

	sprite_tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		spawn_duration
	)


	# --------------------------------------------------------
	# Pulso de luz
	# --------------------------------------------------------

	var light_tween := create_tween()

	light_tween.tween_property(
		spawn_light,
		"energy",
		spawn_light_energy,
		spawn_duration * 0.5
	)

	light_tween.tween_property(
		spawn_light,
		"energy",
		0.0,
		spawn_duration * 0.5
	)


	# --------------------------------------------------------
	# Termina el spawn
	# --------------------------------------------------------

	sprite_tween.tween_callback(_finish_spawn)


func _finish_spawn() -> void:
	is_spawning = false


# ============================================================
# RAYO ELÉCTRICO
# ============================================================

func _show_electric_flash() -> void:

	if not electric_flash:
		return


	var points := PackedVector2Array([
		Vector2(-18, -20),
		Vector2(-10, -8),
		Vector2(-15, 2),
		Vector2(-5, 8),
		Vector2(-10, 20),
		Vector2(0, 10),
		Vector2(8, 20),
		Vector2(5, 7),
		Vector2(17, 2),
		Vector2(10, -8),
		Vector2(18, -20)
	])


	electric_flash.points = points

	electric_flash.visible = true
	electric_flash.modulate = Color.WHITE


	var tween := create_tween()

	tween.tween_property(
		electric_flash,
		"modulate:a",
		0.0,
		electric_duration
	)

	tween.tween_callback(
		_hide_electric_flash
	)


func _hide_electric_flash() -> void:

	electric_flash.visible = false
	electric_flash.modulate.a = 1.0


# ============================================================
# IA
# ============================================================

func update_state() -> void:

	if player == null:
		state = State.PATROL
		return


	var distance_to_player: float = global_position.distance_to(
		player.global_position
	)


	var vertical_distance: float = abs(
		global_position.y - player.global_position.y
	)


	if (
		distance_to_player <= chase_distance
		and vertical_distance <= max_vertical_distance
	):
		state = State.CHASE
	else:
		state = State.PATROL


# ============================================================
# PATRULLA
# ============================================================

func patrol() -> void:

	if not is_on_floor():
		velocity.x = 0.0
		return


	if is_on_wall():
		change_direction()

	elif not floor_detector.is_colliding():
		change_direction()


	velocity.x = direction * speed


# ============================================================
# PERSECUCIÓN
# ============================================================

func chase_player() -> void:

	if not is_on_floor():
		velocity.x = 0.0
		return


	var target_direction: float = signf(
		player.global_position.x - global_position.x
	)


	if target_direction != 0.0 and target_direction != direction:

		direction = target_direction
		update_floor_detector()


	# No se tira del borde para perseguir al jugador
	if not floor_detector.is_colliding():

		velocity.x = 0.0
		return


	velocity.x = direction * speed


# ============================================================
# CAMBIAR DIRECCIÓN
# ============================================================

func change_direction() -> void:

	direction *= -1.0
	update_floor_detector()


func update_floor_detector() -> void:

	floor_detector.position.x = (
		abs(floor_detector.position.x) * direction
	)


# ============================================================
# RECIBIR DAÑO
# ============================================================

func take_damage(amount: int) -> void:

	if is_dying or is_spawning:
		return


	health -= amount


	print(
		"Enemigo recibió daño. Vida restante: ",
		health
	)


	# Retroceso al recibir un disparo
	if player != null:

		var knockback_direction: float = signf(
			global_position.x - player.global_position.x
		)

		if knockback_direction == 0.0:
			knockback_direction = 1.0

		velocity.x = knockback_direction * damage_knockback

	else:

		velocity.x = -direction * damage_knockback


	velocity.y = damage_jump


	# Rayo eléctrico
	_show_electric_flash()


	if health <= 0:
		die()


# ============================================================
# MUERTE
# ============================================================

func die() -> void:

	if is_dying:
		return


	is_dying = true


	# Desactivar lógica
	set_physics_process(false)


	# Detener daño por contacto
	if _damage_tick_timer:
		_damage_tick_timer.stop()


	_bodies_in_damage_area.clear()


	# Desactivar colisiones
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)


	for child in get_children():

		if child is Area2D:

			child.set_collision_layer_value(
				1,
				false
			)

			child.set_collision_mask_value(
				1,
				false
			)


	# Efecto de muerte
	var tween := create_tween()


	tween.tween_method(
		_set_flash,
		0.0,
		1.0,
		0.15
	)


	tween.tween_method(
		_set_fade,
		0.0,
		1.0,
		0.5
	)


	tween.tween_callback(queue_free)


# ============================================================
# SHADERS
# ============================================================

func _set_dissolve(value: float) -> void:

	if sprite and sprite.material:

		sprite.material.set_shader_parameter(
			"dissolve_amount",
			value
		)


func _set_flash(value: float) -> void:

	if sprite and sprite.material:

		sprite.material.set_shader_parameter(
			"flash_amount",
			value
		)


func _set_fade(value: float) -> void:

	if sprite and sprite.material:

		sprite.material.set_shader_parameter(
			"fade_amount",
			value
		)


func _set_progress(value: float) -> void:

	if sprite and sprite.material:

		sprite.material.set_shader_parameter(
			"progress",
			value
		)


# ============================================================
# DAMAGE AREA
# ============================================================

func _on_damage_area_body_entered(body: Node2D) -> void:

	if is_dying or is_spawning:
		return


	if body.has_method("take_damage"):

		# El robot hace daño al jugador
		body.take_damage(contact_damage)


		# ----------------------------------------------------
		# Retroceso alejándose del jugador
		# ----------------------------------------------------

		var knockback_direction: float = signf(
			global_position.x - body.global_position.x
		)


		if knockback_direction == 0.0:
			knockback_direction = 1.0


		velocity.x = (
			knockback_direction
			* contact_knockback
		)

		velocity.y = contact_jump


		# ----------------------------------------------------
		# Destello eléctrico
		# ----------------------------------------------------

		_show_electric_flash()


		# ----------------------------------------------------
		# Registrar jugador
		# ----------------------------------------------------

		if body not in _bodies_in_damage_area:

			_bodies_in_damage_area.append(body)


		if _damage_tick_timer.is_stopped():

			_damage_tick_timer.start()


# ============================================================
# SALIÓ DEL DAMAGE AREA
# ============================================================

func _on_damage_area_body_exited(body: Node2D) -> void:

	_bodies_in_damage_area.erase(body)


	if _bodies_in_damage_area.is_empty():

		_damage_tick_timer.stop()


# ============================================================
# DAMAGE TICK
# ============================================================

func _on_damage_tick_timeout() -> void:

	if is_dying:

		_damage_tick_timer.stop()
		return


	for body in _bodies_in_damage_area.duplicate():

		if (
			is_instance_valid(body)
			and body.has_method("take_damage")
		):

			# Daño periódico
			body.take_damage(contact_damage)


			# Destello eléctrico
			_show_electric_flash()


			# Pequeño retroceso
			var knockback_direction: float = signf(
				global_position.x - body.global_position.x
			)


			if knockback_direction == 0.0:
				knockback_direction = 1.0


			velocity.x = (
				knockback_direction
				* contact_knockback
			)

			velocity.y = contact_jump

		else:

			_bodies_in_damage_area.erase(body)


	if _bodies_in_damage_area.is_empty():

		_damage_tick_timer.stop()
