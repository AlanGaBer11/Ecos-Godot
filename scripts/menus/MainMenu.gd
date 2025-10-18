# /scripts/MainMenu.gd
extends Control

@onready var play_btn = $VBoxContainer/PlayButton
@onready var options_btn = $VBoxContainer/OptionsButton
@onready var credits_btn = $VBoxContainer/CreditsButton
@onready var exit_btn = $VBoxContainer/ExitButton
@onready var music = $Music

# Scenes
@export var scene_level1: PackedScene = preload("res://scenes/niveles/Nivel_Bosque.tscn")
@export var scene_options_path: String = "res://scenes/menus/OptionsMenu.tscn"


func _ready():
	# Reproducir la musica a través del AudioManger
	if AudioManager:
		AudioManager.play_music(preload("res://assets/audio/MainTheme.ogg"))
	else:
			music.play()
	
	# Conectar botones
	play_btn.pressed.connect(_on_play_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	#credits_btn.pressed.connect(_on_credits_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

	# Opcional: setear primer foco para navegación con teclado/joy
	play_btn.grab_focus()
	

func _on_play_pressed():
	#_play_click()
	# si tienes la ruta de escena en PackedScene exportado:
	if scene_level1:
		get_tree().change_scene_to_file("res://scenes/niveles/Nivel_Bosque.tscn")
	else:
		push_error("No se encontró el nivel")

func _on_options_pressed():
	#_play_click()
	get_tree().change_scene_to_file(scene_options_path)

#func _on_credits_pressed():
#	_play_click()
#	get_tree().change_scene_to_file(scene_credits_path)

func _on_exit_pressed():
	get_tree().quit()
