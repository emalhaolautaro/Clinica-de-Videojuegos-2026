extends CharacterBody2D

const ENEMY_BULLET_SCENE: PackedScene = preload("res://projectiles/enemy_bullet.tscn")

@export var max_health: int = 3
@export var shoot_interval: float = 5.0

var health: int
var player: CharacterBody2D
var direction: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker2D = $Muzzle

var gravity: float = float(
	ProjectSettings.get_setting("physics/2d/default_gravity")
)


func _ready() -> void:
	health = max_health

	if shoot_timer:
		shoot_timer.wait_time = shoot_interval
		shoot_timer.timeout.connect(shoot_at_player)
		shoot_timer.start()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if player:
		var target_direction := signf(player.global_position.x - global_position.x)
		if target_direction != 0:
			if sprite:
				sprite.flip_h = target_direction < 0
			if muzzle:
				muzzle.position.x = abs(muzzle.position.x) * target_direction

	move_and_slide()


func shoot_at_player() -> void:
	if player == null or not is_instance_valid(player):
		return

	var spawn_pos: Vector2
	if muzzle:
		spawn_pos = muzzle.global_position
	else:
		spawn_pos = global_position

	var aim_direction := (player.global_position - spawn_pos).normalized()

	var bullet = ENEMY_BULLET_SCENE.instantiate()
	bullet.direction = aim_direction
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = spawn_pos


func take_damage(amount: int) -> void:
	health -= amount
	print("Torreta recibió daño. Vida restante: ", health)

	if health <= 0:
		die()


func die() -> void:
	queue_free()


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)
