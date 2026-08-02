extends Area2D

@export var speed := 600.0
@export var damage := 1

var direction := 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	$Sprite2D.flip_h = direction < 0


func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
