extends CharacterBody2D
const BULLET_SCENE := preload("res://projectiles/bullet.tscn")

@onready var muzzle: Marker2D = $Muzzle
var facing_direction := 1

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func shoot() -> void:
	var bullet = BULLET_SCENE.instantiate()

	bullet.global_position = muzzle.global_position
	bullet.direction = facing_direction
	get_tree().current_scene.add_child(bullet)
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_J and event.pressed and not event.echo:
			shoot()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		facing_direction = int(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
