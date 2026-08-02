extends CharacterBody2D

@export var speed := 100.0
@export var health := 3

@export var contact_damage := 1
@onready var damage_area: Area2D = $DamageArea

var player: CharacterBody2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	damage_area.body_entered.connect(_on_damage_area_body_entered)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(contact_damage)

func take_damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		queue_free()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if player == null:
		return

	if player.global_position.x > global_position.x:
		velocity.x = speed
	else:
		velocity.x = -speed

	move_and_slide()
