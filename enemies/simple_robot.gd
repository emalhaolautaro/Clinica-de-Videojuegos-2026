extends CharacterBody2D

@export var speed := 100.0
@export var health := 3

@export var contact_damage := 1
@onready var damage_area: Area2D = $DamageArea

var player: CharacterBody2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var was_in_contact := false
var contact_timer := 0.0

func _ready() -> void:
	pass

func take_damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		queue_free()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if player != null:
		if player.global_position.x > global_position.x:
			velocity.x = speed
		else:
			velocity.x = - speed

	move_and_slide()

	# Recopilar todos los cuerpos con los que el enemigo está en contacto físico
	# o que se superponen con su DamageArea.
	var current_damageables = []
	
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.has_method("take_damage") and not collider in current_damageables:
			current_damageables.append(collider)
			
	for body in damage_area.get_overlapping_bodies():
		if body.has_method("take_damage") and not body in current_damageables:
			current_damageables.append(body)
			
	# Lógica de daño continuo
	if current_damageables.size() > 0:
		if not was_in_contact:
			# Primer momento de contacto
			for body in current_damageables:
				body.take_damage(contact_damage)
			was_in_contact = true
			contact_timer = 0.0
		else:
			# Si siguen en contacto, vuelve a hacer daño al segundo
			contact_timer += delta
			if contact_timer >= 1.0:
				for body in current_damageables:
					body.take_damage(contact_damage)
				contact_timer -= 1.0
	else:
		was_in_contact = false
		contact_timer = 0.0
