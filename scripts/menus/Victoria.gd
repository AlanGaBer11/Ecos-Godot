extends Control

func _ready() -> void:
	$PanelContainer/VBoxContainer/ExitButton.pressed.connect(_continuar)

func _continuar() -> void:
	# Aquí cambias a siguiente nivel o menú
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
