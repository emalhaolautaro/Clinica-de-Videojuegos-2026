extends Node2D

@onready var click_sfx: AudioStreamPlayer2D = $"ClickSFX"

# ============================================================
# RAYOS RANDOM DE FONDO
# ============================================================

@export var background_bolt_min_interval := 0.8
@export var background_bolt_max_interval := 2.0
@export var background_bolts_per_burst := 3
@export var background_bolt_segments := 10
@export var background_bolt_jitter := 40.0
@export var background_bolt_fade_duration := 0.3
@export var background_bolt_color := Color(0.6, 0.9, 1.0)
@export var background_bolt_width := 2.0

@onready var background_bolt_timer: Timer = $BackgroundBoltTimer


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	print("LightningEffects ready")
	background_bolt_timer.timeout.connect(_spawn_background_bolts)
	_schedule_next_background_bolt()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("click detectado, click_sfx es null: ", click_sfx == null)
		click_sfx.play()

# ============================================================
# RAYOS DE FONDO
# ============================================================

func _schedule_next_background_bolt() -> void:
	background_bolt_timer.wait_time = randf_range(
		background_bolt_min_interval,
		background_bolt_max_interval
	)
	background_bolt_timer.start()


func _spawn_background_bolts() -> void:
	for i in range(background_bolts_per_burst):
		_spawn_single_background_bolt()

	_schedule_next_background_bolt()


func _spawn_single_background_bolt() -> void:
	var viewport_size := get_viewport_rect().size
	var start := Vector2(randf_range(0, viewport_size.x), 0)
	var end := Vector2(randf_range(0, viewport_size.x), viewport_size.y)

	var bolt := Line2D.new()
	bolt.width = background_bolt_width
	bolt.default_color = background_bolt_color
	bolt.points = _generate_lightning_points(
		start,
		end,
		background_bolt_segments,
		background_bolt_jitter
	)
	add_child(bolt)

	var tween := create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, background_bolt_fade_duration)
	tween.tween_callback(bolt.queue_free)


# ============================================================
# GENERADOR DE PUNTOS EN ZIGZAG
# ============================================================

func _generate_lightning_points(
	start: Vector2,
	end: Vector2,
	segments: int,
	jitter: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(start)

	var perpendicular := (end - start).normalized().rotated(PI / 2)

	for i in range(1, segments):
		var t := float(i) / float(segments)
		var base_point := start.lerp(end, t)
		var offset := perpendicular * randf_range(-jitter, jitter)
		points.append(base_point + offset)

	points.append(end)
	return points
