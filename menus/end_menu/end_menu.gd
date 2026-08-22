extends Control

@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel
@onready var primary_button: Button = $CenterContainer/VBoxContainer/PrimaryButton
@onready var click_sfx: AudioStreamPlayer2D = $ClickSFX

var is_victory := false


func _ready() -> void:
	is_victory = GameManager.last_result_was_victory

	if is_victory:
		result_label.text = "¡VICTORIA!"
		primary_button.text = "JUGAR DE NUEVO"
		primary_button.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	else:
		result_label.text = "DERROTA"
		primary_button.text = "REINTENTAR"
		primary_button.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))


func _on_primary_button_pressed() -> void:
	if is_victory:
		GameManager.return_to_main_menu()
	else:
		GameManager.restart_level()


func _on_main_menu_button_pressed() -> void:
	GameManager.return_to_main_menu()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("click detectado, click_sfx es null: ", click_sfx == null)
		click_sfx.play()
