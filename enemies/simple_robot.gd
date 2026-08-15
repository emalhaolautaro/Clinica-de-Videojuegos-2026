extends CharacterBody2D

const DISSOLVE_SHADER: Shader = preload("res://enemies/dissolve.gdshader")
const DEATH_SHADER: Shader = preload("res://enemies/death_flash.gdshader")
const PIXELATE_SHADER: Shader = preload("res://enemies/pixelate_death.gdshader")

enum State {
	PATROL,
	CHASE
}

@export var speed: float = 40.0
@export var chase_distance: float = 180.0
@export var max_vertical_distance: float = 40.0
@export var max_health: int = 3
@export var dissolve_duration: float = 0.8
@export var contact_damage: int = 1
@export var damage_tick_interval: float = 1.0

var player: CharacterBody2D
var direction: float = 1.0
var state: State = State.PATROL
var health: int
var is_dying: bool = false
var _bodies_in_damage_area: Array[Node2D] = []
var _damage_tick_timer: Timer

@onready var sprite: Sprite2D = $Sprite2D
@onready var floor_detector: RayCast2D = $FloorDetector

var gravity: float = float(
	ProjectSettings.get_setting("physics/2d/default_gravity")
)


func _ready() -> void:
	health = max_health
	_setup_dissolve_shader()

	if randf() < 0.5:
		direction = -1.0
	else:
		direction = 1.0

	update_floor_detector()

	_damage_tick_timer = Timer.new()
	_damage_tick_timer.wait_time = damage_tick_interval
	_damage_tick_timer.timeout.connect(_on_damage_tick_timeout)
	add_child(_damage_tick_timer)

	var damage_area = $DamageArea
	if damage_area:
		damage_area.body_exited.connect(_on_damage_area_body_exited)


func _setup_dissolve_shader() -> void:
	#Para el efecto de DISOLVE------------------------------------------------
	#if not sprite:
	#	return
	#var shader_material := ShaderMaterial.new()
	#shader_material.shader = DISSOLVE_SHADER
	#var noise := FastNoiseLite.new()
	#noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	#noise.frequency = 0.05
	#var noise_tex := NoiseTexture2D.new()
	#noise_tex.noise = noise
	#noise_tex.width = 256
	#noise_tex.height = 256
	#shader_material.set_shader_parameter("noise_texture", noise_tex)
	#shader_material.set_shader_parameter("dissolve_amount", 0.0)
	#sprite.material = shader_material
	#-------------------------------------------------------------------------
	#Efecto de flash + fade y/o PIXELATE--------------------------------------
	if not sprite:
		return
	var shader_material := ShaderMaterial.new()
	shader_material.shader = DEATH_SHADER
	sprite.material = shader_material


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	update_state()

	match state:
		State.PATROL:
			patrol()

		State.CHASE:
			chase_player()

	move_and_slide()


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


func patrol() -> void:
	if not is_on_floor():
		velocity.x = 0.0
		return

	if is_on_wall():
		change_direction()

	elif not floor_detector.is_colliding():
		change_direction()

	velocity.x = direction * speed


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

	# Si perseguir al jugador implicaría caerse,
	# el enemigo se queda en el borde.
	if not floor_detector.is_colliding():
		velocity.x = 0.0
		return

	velocity.x = direction * speed


func change_direction() -> void:
	direction *= -1.0
	update_floor_detector()


func update_floor_detector() -> void:
	floor_detector.position.x = abs(floor_detector.position.x) * direction


func take_damage(amount: int) -> void:
	if is_dying:
		return

	health -= amount
	print("Enemigo recibió daño. Vida restante: ", health)

	if health <= 0:
		die()


func die() -> void:
	if is_dying:
		return
	is_dying = true

	# Desactivar lógica del enemigo
	set_physics_process(false)
	_damage_tick_timer.stop()
	_bodies_in_damage_area.clear()

	# Desactivar colisiones
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	for child in get_children():
		if child is Area2D:
			child.set_collision_layer_value(1, false)
			child.set_collision_mask_value(1, false)

	var tween := create_tween()
	tween.tween_method(_set_flash, 0.0, 1.0, 0.15)
	tween.tween_method(_set_fade, 0.0, 1.0, 0.5)
	tween.tween_callback(queue_free)

#Para el efecto de disolve
func _set_dissolve(value: float) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("dissolve_amount", value)

#Para el efecto de flash
func _set_flash(value: float) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("flash_amount", value)

#Para el efecto de fade
func _set_fade(value: float) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("fade_amount", value)

#Para el efecto de pixelar
func _set_progress(value: float) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("progress", value)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if is_dying:
		return
	if body.has_method("take_damage"):
		body.take_damage(contact_damage)
		if body not in _bodies_in_damage_area:
			_bodies_in_damage_area.append(body)
		if _damage_tick_timer.is_stopped():
			_damage_tick_timer.start()


func _on_damage_area_body_exited(body: Node2D) -> void:
	_bodies_in_damage_area.erase(body)
	if _bodies_in_damage_area.is_empty():
		_damage_tick_timer.stop()


func _on_damage_tick_timeout() -> void:
	if is_dying:
		_damage_tick_timer.stop()
		return
	for body in _bodies_in_damage_area.duplicate():
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(contact_damage)
		else:
			_bodies_in_damage_area.erase(body)
	if _bodies_in_damage_area.is_empty():
		_damage_tick_timer.stop()
