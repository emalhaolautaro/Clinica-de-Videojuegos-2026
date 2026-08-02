extends CharacterBody2D


# Escenas
const BULLET_SCENE: PackedScene = preload("res://projectiles/bullet.tscn")


# Movimiento
@export var speed := 300.0
@export var jump_velocity := -400.0

var gravity: float = ProjectSettings.get_setting(
	"physics/2d/default_gravity"
)
var facing_direction := 1


# Vida
@export var max_health := 5
var health: int


# Nodos
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_horizontal_movement()

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
	else:
		velocity.x = move_toward(velocity.x, 0, speed)


# Disparo

func shoot() -> void:
	var bullet = BULLET_SCENE.instantiate()

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = muzzle.global_position
	bullet.direction = facing_direction


# Vida

func take_damage(amount: int) -> void:
	health -= amount
	print("Vida del jugador: ", health)

	if health <= 0:
		die()


func die() -> void:
	print("El jugador murió")
	queue_free()
