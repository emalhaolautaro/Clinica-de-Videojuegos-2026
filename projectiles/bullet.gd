extends Area2D

@export var speed := 600.0
var direction := 1

func _ready() -> void:
	$Sprite2D.flip_h = direction < 0
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta
