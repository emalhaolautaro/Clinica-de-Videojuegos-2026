extends StaticBody2D

const EXPLOSION_SHADER: Shader = preload("res://objects/batteries/explosion.gdshader")

signal destroyed

@export var max_health := 3
@export var explosion_duration: float = 0.5
var health: int
var is_dying: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	_setup_explosion_shader()


func _setup_explosion_shader() -> void:
	if not sprite:
		return
	var shader_material := ShaderMaterial.new()
	shader_material.shader = EXPLOSION_SHADER

	# Generar textura de ruido procedural para bordes orgánicos
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08
	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = 128
	noise_tex.height = 128
	shader_material.set_shader_parameter("noise_texture", noise_tex)

	sprite.material = shader_material


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

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	var tween := create_tween()
	tween.tween_method(_set_flash, 0.0, 1.0, 0.15)
	tween.tween_method(_set_explosion, 0.0, 1.2, explosion_duration)
	tween.parallel().tween_method(_set_flash, 1.0, 0.0, explosion_duration * 0.3)
	tween.tween_callback(queue_free)


func _set_flash(value: float) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("flash_amount", value)


func _set_explosion(value: float) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("explosion_progress", value)
