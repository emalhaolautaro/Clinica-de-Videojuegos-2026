extends CharacterBody2D


# Escenas
const BULLET_SCENE: PackedScene = preload("res://projectiles/bullet.tscn")


# Movimiento
@export var speed := 150.0
@export var jump_velocity := -450.0

var gravity: float = ProjectSettings.get_setting(
	"physics/2d/default_gravity"
)
var facing_direction := 1


# Vida
@export var max_health := 5
var health: int

# Energía
@export var max_energy := 4.0
@export var energy_recharge_rate := 1.0
var energy: float


# Nodos
@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: Sprite2D = $Sprite2D

#Señal Muerte
signal died

# Señales de vida
signal health_changed(new_health: int)
signal max_health_changed(max_health: int)

# Señales de energía
signal energy_changed(new_energy: float)
signal max_energy_changed(max_energy: float)

func _ready() -> void:
	health = max_health
	max_health_changed.emit(max_health)
	health_changed.emit(health)
	
	energy = max_energy
	max_energy_changed.emit(max_energy)
	energy_changed.emit(energy)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_horizontal_movement()
	
	if energy < max_energy:
		energy = min(energy + energy_recharge_rate * delta, max_energy)
		energy_changed.emit(energy)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_J and event.pressed and not event.echo:
			shoot()


# Movimiento

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func handle_jump() -> void:
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity


func handle_horizontal_movement() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * speed
		facing_direction = int(sign(direction))
		if direction < 0:
			sprite.flip_h = true
		elif direction > 0:
			sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, speed)


# Disparo

func shoot() -> void:
	if energy < 1.0:
		return
	
	energy -= 1.0
	energy_changed.emit(energy)
	
	var bullet = BULLET_SCENE.instantiate()

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = muzzle.global_position
	bullet.direction = facing_direction


# Vida

func take_damage(amount: int) -> void:
	health -= amount
	health_changed.emit(health)
	print("Vida del jugador: ", health)

	if health <= 0:
		die()


func die() -> void:
	print("El jugador murió")
	died.emit()
	queue_free()
