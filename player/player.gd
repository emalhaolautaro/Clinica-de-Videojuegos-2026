extends CharacterBody2D


# Escenas
const BULLET_SCENE: PackedScene = preload("res://projectiles/bullet.tscn")


# Movimiento
@export var speed := 150.0

var jump_velocity := -450.0
var second_jump_multiplier := 0.75

var gravity: float = ProjectSettings.get_setting(
	"physics/2d/default_gravity"
)
var facing_direction := 1

var max_jumps := 2
var jumps_left: int


# Vida
@export var max_health := 5
var health: int


# Energía
@export var max_energy := 4.0
@export var energy_recharge_rate := 1.0
var energy: float
@export var reload_rate := 1.8
var is_reloading = false
var is_shooting = false


# Nodos
@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spark_particles: CPUParticles2D = $CPUParticles2D
@onready var flashlight: PointLight2D = $Flashlight
@onready var shoot_sfx: AudioStreamPlayer2D = $ShootSFX

# Flashlight de recarga
@export var flashlight_min_energy := 0.6
@export var flashlight_max_energy := 1.4
@export var flashlight_flicker_speed := 15.0

var _flashlight_target_energy := 1.0


# Señal muerte
signal died


# Señales de vida
signal health_changed(new_health: int)
signal max_health_changed(max_health: int)


# Señales de energía
signal energy_changed(new_energy: float)
signal max_energy_changed(max_energy: float)


func _ready() -> void:
	jumps_left = max_jumps

	health = max_health
	max_health_changed.emit(max_health)
	health_changed.emit(health)

	energy = max_energy
	max_energy_changed.emit(max_energy)
	energy_changed.emit(energy)
	
	if flashlight:
		flashlight.energy = 0.0
	
	_setup_spark_particles()
	
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_horizontal_movement()
	handle_energy(delta)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_F and event.pressed and not event.echo:
			shoot()


# Movimiento

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump() -> void:
	# Al tocar el piso recuperamos ambos saltos
	if is_on_floor():
		jumps_left = max_jumps

	if Input.is_action_just_pressed("ui_up") and jumps_left > 0:
		# Primer salto
		if jumps_left == max_jumps:
			velocity.y = jump_velocity

		# Segundo salto: un poco más débil
		else:
			velocity.y = jump_velocity * second_jump_multiplier

		jumps_left -= 1


func handle_horizontal_movement() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * speed
		facing_direction = int(sign(direction))

		if direction < 0:
			sprite.flip_h = true
		elif direction > 0:
			sprite.flip_h = false

		if not is_shooting:
			sprite.play("run")
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			speed
		)
		if not is_shooting:
			sprite.play("idle")

# Disparo

func shoot() -> void:
	if energy < 1.0:
		return

	is_shooting = true
	sprite.play("shoot")
	shoot_sfx.pitch_scale = randf_range(0.95, 1.05)
	shoot_sfx.play()
	energy -= 1.0
	energy_changed.emit(energy)

	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = facing_direction
	bullet.global_position = muzzle.global_position

	get_tree().current_scene.add_child(bullet)


func _on_animation_finished() -> void:
	if sprite.animation == "shoot":
		is_shooting = false
	

# Vida

func take_damage(amount: int) -> void:
	health -= amount
	health_changed.emit(health)

	print("Vida del jugador: ", health)

	if health <= 0:
		die()

# Partículas de recarga y energía
func handle_energy(delta: float) -> void:
	if energy >= max_energy:
		is_reloading = false
		if spark_particles:
			spark_particles.emitting = false
		if flashlight:
			flashlight.energy = 0.0
		return

	if Input.is_key_pressed(KEY_R):
		is_reloading = true
		energy = min(energy + reload_rate * delta, max_energy)
	else:
		is_reloading = false
		energy = min(energy + energy_recharge_rate * delta, max_energy)
	
	if spark_particles:
		spark_particles.emitting = is_reloading
		
	if flashlight:
		if is_reloading:
			_update_flashlight_flicker(delta)
		else:
			flashlight.energy = 0.0

	energy_changed.emit(energy)

func _update_flashlight_flicker(delta: float) -> void:
	if randf() < 0.3:
		_flashlight_target_energy = randf_range(
			flashlight_min_energy,
			flashlight_max_energy
		)

	flashlight.energy = lerp(
		flashlight.energy,
		_flashlight_target_energy,
		flashlight_flicker_speed * delta
	)
	
	print("flashlight energy: ", flashlight.energy)

func _setup_spark_particles() -> void:
	if not spark_particles:
		return
	spark_particles.emitting = false
	spark_particles.amount = 32
	spark_particles.lifetime = 0.35
	spark_particles.one_shot = false
	spark_particles.explosiveness = 0.5
	spark_particles.randomness = 0.8
	spark_particles.spread = 180.0
	spark_particles.direction = Vector2.UP
	spark_particles.initial_velocity_min = 20.0
	spark_particles.initial_velocity_max = 60.0
	spark_particles.gravity = Vector2(0, 150)
	spark_particles.scale_amount_min = 0.4
	spark_particles.scale_amount_max = 0.7
	spark_particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(1, 1, 0.6)) # amarillo eléctrico
	color_ramp.add_point(0.5, Color(0.6, 0.9, 1.0)) # celeste eléctrico
	color_ramp.set_color(1, Color(1, 1, 1, 0)) # fade a transparente
	spark_particles.color_ramp = color_ramp

# Muerte

func die() -> void:
	print("El jugador murió")
	died.emit()
	queue_free()
