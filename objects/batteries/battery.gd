extends StaticBody2D

const EXPLOSION_SHADER: Shader = preload("res://objects/batteries/explosion.gdshader")

signal destroyed

@export var max_health := 1
@export var light_color: Color = Color(1.0, 0.15, 0.15, 1.0)
@export var min_light_energy: float = 0.4
@export var max_light_energy: float = 1.8
@export var pulse_duration: float = 0.8
@export var explosion_duration: float = 0.55

var health: int
var is_dying: bool = false
var _light_tween: Tween
var _shader_material: ShaderMaterial

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var exploid_sfx: AudioStreamPlayer2D = $ExploidSFX
@onready var point_light: PointLight2D = $PointLight2D


func _ready() -> void:
	health = max_health
	_setup_shader()
	_setup_light()


func _setup_shader() -> void:
	if not sprite:
		return
	
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = EXPLOSION_SHADER

	# Generar textura de ruido para una onda orgánica
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08

	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = 128
	noise_tex.height = 128
	_shader_material.set_shader_parameter("noise_texture", noise_tex)

	sprite.material = _shader_material


func _setup_light() -> void:
	if not point_light:
		return
	
	point_light.enabled = true
	point_light.color = light_color
	point_light.energy = min_light_energy

	_light_tween = create_tween().set_loops()
	_light_tween.tween_property(point_light, "energy", max_light_energy, pulse_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_light_tween.tween_property(point_light, "energy", min_light_energy, pulse_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func take_damage(amount: int) -> void:
	if is_dying:
		return
	health -= amount
	print("Batería recibió daño. Vida restante: ", health)

	if health <= 0:
		die()


func die() -> void:
	if is_dying:
		return
	is_dying = true

	print("Batería destruida")
	destroyed.emit()

	# Desactivar colisiones de inmediato
	collision_layer = 0
	collision_mask = 0
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	if exploid_sfx:
		exploid_sfx.play()

	# Animación de la luz al explotar: destello cálido intenso y apagado
	if _light_tween:
		_light_tween.kill()

	if point_light:
		var light_boom := create_tween()
		light_boom.tween_property(point_light, "color", Color(1.0, 0.7, 0.2), 0.08)
		light_boom.parallel().tween_property(point_light, "energy", 3.5, 0.08)
		light_boom.tween_property(point_light, "energy", 0.0, 0.45)
		light_boom.tween_callback(func(): point_light.enabled = false)

	# Animación de la onda de fuego y aspecto quemado mediante el shader
	if _shader_material:
		var tween := create_tween()
		# 1. Destello inicial
		tween.tween_method(_set_flash, 0.0, 1.0, 0.08)
		tween.tween_method(_set_flash, 1.0, 0.0, 0.15)
		# 2. Onda expansiva de fuego a través del sprite
		tween.parallel().tween_method(_set_explosion_progress, 0.0, 1.2, explosion_duration)
		# 3. Deja la textura con aspecto quemado/dañado permanentemente
		tween.parallel().tween_method(_set_burn_amount, 0.0, 0.75, explosion_duration)

	# Pequeña vibración en el sprite durante la explosión
	_play_sprite_shake()


func _play_sprite_shake() -> void:
	if not sprite:
		return
	var orig_pos := sprite.position
	var shake_tween := create_tween()
	for i in range(5):
		var offset := Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		shake_tween.tween_property(sprite, "position", orig_pos + offset, 0.03)
	shake_tween.tween_property(sprite, "position", orig_pos, 0.04)


func _set_flash(value: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("flash_amount", value)


func _set_explosion_progress(value: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("explosion_progress", value)


func _set_burn_amount(value: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("burn_amount", value)
