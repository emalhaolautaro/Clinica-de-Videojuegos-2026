extends Area2D

@export var speed := 600.0
@export var damage := 1

var direction := 1:
	set(value):
		direction = value
		_update_direction()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	_update_direction()


func _update_direction() -> void:
	if not is_node_ready():
		return
	if direction < 0:
		scale.x = -abs(scale.x)
	else:
		scale.x = abs(scale.x)


func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
