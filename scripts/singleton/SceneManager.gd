extends Node

var previous_scene: String = ""
var is_game_paused: bool = false

func go_to_scene(scene_path: String) -> void:
	previous_scene = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file(scene_path)

func return_to_previous() -> void:
	if previous_scene != "":
		get_tree().change_scene_to_file(previous_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
