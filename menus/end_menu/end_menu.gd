extends Control

@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel
@onready var primary_button: Button = $CenterContainer/VBoxContainer/PrimaryButton

var is_victory := false


func setup(victory: bool) -> void:
	is_victory = victory

	if victory:
		result_label.text = "¡VICTORIA!"
		primary_button.text = "VOLVER AL MENÚ"
	else:
		result_label.text = "DERROTA"
		primary_button.text = "REINTENTAR"


func _on_primary_button_pressed() -> void:
	if is_victory:
		GameManager.return_to_main_menu()
	else:
		GameManager.restart_level()


func _on_main_menu_button_pressed() -> void:
	GameManager.return_to_main_menu()
