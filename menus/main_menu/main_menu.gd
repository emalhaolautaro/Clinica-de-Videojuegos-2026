extends Control

@onready var main_container: Control = $CenterContainer
@onready var how_to_play_container: Control = $HowToPlayContainer
@onready var credits_container: Control = $CreditsContainer
@onready var background = $Menu


func _on_play_button_pressed() -> void:
	GameManager.start_game()


func _on_how_to_play_button_pressed() -> void:
	main_container.visible = false
	background.visible = false
	how_to_play_container.visible = true


func _on_back_button_pressed() -> void:
	how_to_play_container.visible = false
	background.visible = true
	main_container.visible = true


func _on_credits_button_pressed() -> void:
	main_container.visible = false
	background.visible = false
	credits_container.visible = true


func _on_credits_back_button_pressed() -> void:
	credits_container.visible = false
	background.visible = true
	main_container.visible = true


func _on_quit_button_pressed() -> void:
	GameManager.quit_game()
