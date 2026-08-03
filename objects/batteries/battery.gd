extends StaticBody2D

@export var max_health := 3
var health: int

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health -= amount
	print("Batería recibió daño. Vida restante: ", health)
	
	if health <= 0:
		die()

func die() -> void:
	print("Batería destruida")
	queue_free()
