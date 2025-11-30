extends Control

@onready var play_btn = $VBoxContainer/ButtonContainer/PlayButton
@onready var options_btn = $VBoxContainer/ButtonContainer/OptionsButton
@onready var exit_btn = $VBoxContainer/ButtonContainer/ExitButton
@onready var music = $Music

# Scenes
@export var scene_level1: PackedScene = preload("res://scenes/niveles/Nivel_Bosque.tscn")
@export var select_character: String = "res://scenes/menus/SelectCharacter.tscn"
@export var scene_options_path: String = "res://scenes/menus/OptionsMenu.tscn"

func _ready():
	# Reproducir la musica a través del AudioManger
	if AudioManager:
		AudioManager.play_music(preload("res://assets/audio/MainTheme.ogg"))
	else:
		music.play()
	
	# Asegurarse de que el juego NO esté pausado al entrar al MainMenu
	get_tree().paused = false
	
	# Conectar botones
	play_btn.pressed.connect(_on_play_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	#credits_btn.pressed.connect(_on_credits_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	
	# Setear primer foco para navegación con teclado/joy
	play_btn.grab_focus()

func _on_play_pressed():
	#_play_click()
	# si tienes la ruta de escena en PackedScene exportado:
	if select_character:
		
		SceneManager.is_game_paused = false  # Resetear el estado de pausa
		get_tree().change_scene_to_file("res://scenes/menus/SelectCharacter.tscn")
	else:
		push_error("No se encontró el nivel")

func _on_options_pressed():
	#_play_click()
	SceneManager.is_game_paused = false  # Marcar que venimos del MainMenu
	SceneManager.go_to_scene(scene_options_path)

func _on_exit_pressed():
	get_tree().quit()
