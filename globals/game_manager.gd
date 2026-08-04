extends Node

const MAIN_MENU_PATH := "res://menus/main_menu/main_menu.tscn"
const LEVEL_PATH := "res://levels/level.tscn"
const END_MENU_PATH := "res://menus/end_menu/end_menu.tscn"

var last_result_was_victory := false


func start_game() -> void:
	get_tree().change_scene_to_file(LEVEL_PATH)


func finish_game(victory: bool) -> void:
	last_result_was_victory = victory
	get_tree().call_deferred("change_scene_to_file", END_MENU_PATH)


func restart_level() -> void:
	get_tree().change_scene_to_file(LEVEL_PATH)


func return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func quit_game() -> void:
	get_tree().quit()
