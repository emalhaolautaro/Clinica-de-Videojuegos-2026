extends CanvasLayer

@onready var resume_button: Button = $ColorRect/VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $ColorRect/VBoxContainer/MainMenuButton

func _ready() -> void:
	# El menú arranca oculto
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause() -> void:
	# Si estamos en una pantalla donde no deberíamos pausar (como el main menu), lo evitamos
	if get_tree().current_scene.name == "MainMenu" or get_tree().current_scene.name == "EndMenu":
		return
		
	var new_pause_state: bool = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	visible = false
	GameManager.return_to_main_menu()
