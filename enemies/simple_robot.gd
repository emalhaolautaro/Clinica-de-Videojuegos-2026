extends CharacterBody2D

enum State {
	PATROL,
	CHASE
}

@export var speed: float = 40.0
@export var chase_distance: float = 180.0
@export var max_vertical_distance: float = 40.0
@export var max_health: int = 3

var player: CharacterBody2D
var direction: float = 1.0
var state: State = State.PATROL
var health: int

@onready var floor_detector: RayCast2D = $FloorDetector

var gravity: float = float(
	ProjectSettings.get_setting("physics/2d/default_gravity")
)


func _ready() -> void:
	health = max_health

	if randf() < 0.5:
		direction = -1.0
	else:
		direction = 1.0

	update_floor_detector()


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
	health -= amount
	print("Enemigo recibió daño. Vida restante: ", health)

	if health <= 0:
		die()


func die() -> void:
	queue_free()


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)
