extends Control

@onready var music_slider : HSlider = $Panel/VBoxContainer/MucisBoxContainer/MusicSlider
@onready var sfx_slider   : HSlider = $Panel/VBoxContainer/SfxBoxContainer/SfxSlider
@onready var music_label  : Label = $Panel/VBoxContainer/MucisBoxContainer/LabelMusic
@onready var sfx_label    : Label = $Panel/VBoxContainer/SfxBoxContainer/LabelSfx
@onready var fullscreen_cb: CheckBox = $Panel/VBoxContainer/FullScreen
@onready var save_btn     : Button = $Panel/VBoxContainer/HBoxContainer/SaveButton
@onready var back_btn     : Button = $Panel/VBoxContainer/HBoxContainer/ExitButton

const CONFIG_PATH: String = "user://settings.cfg"
const SECTION: String = "audio"

func _ready() -> void:
	# --- Sincronizar UI con los valores actuales de AudioManager ---
	music_slider.value = AudioManager.music_volume * 100.0
	sfx_slider.value = AudioManager.sfx_volume * 100.0
	
	# --- Cargar estado de fullscreen ---
	_load_fullscreen_config()
	
	# --- Actualizar labels iniciales ---
	_update_music_label(music_slider.value)
	_update_sfx_label(sfx_slider.value)
	
	# --- Reproducir música de fondo si no se está reproduciendo ---
	if not AudioManager.music_player.playing:
		AudioManager.play_music(preload("res://assets/audio/MainTheme.ogg"))
	
	# --- Conectar señales ---
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	save_btn.pressed.connect(_on_save_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	
	music_slider.grab_focus()

# --- Sliders ---
func _on_music_slider_changed(value: float) -> void:
	var linear: float = value / 100.0
	AudioManager.set_music_volume(linear)
	_update_music_label(value)

func _on_sfx_slider_changed(value: float) -> void:
	var linear: float = value / 100.0
	AudioManager.set_sfx_volume(linear)
	_update_sfx_label(value)

# --- Actualizar labels ---
func _update_music_label(value: float) -> void:
	music_label.text = "%d%%" % int(value)

func _update_sfx_label(value: float) -> void:
	sfx_label.text = "%d%%" % int(value)

# --- Botones ---
func _on_save_pressed() -> void:
	# Aplicar fullscreen
	if fullscreen_cb.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Guardar configuración
	_save_config()
	
	# Volver a la escena anterior
	_return_to_previous_scene()

func _on_back_pressed() -> void:
	# Volver sin guardar
	_return_to_previous_scene()

func _return_to_previous_scene() -> void:
	# Si venimos del juego pausado, volver al juego
	if SceneManager.is_game_paused and SceneManager.previous_scene != "":
		print("Regresando al juego pausado: ", SceneManager.previous_scene)
		get_tree().change_scene_to_file(SceneManager.previous_scene)
	else:
		# Si venimos del MainMenu, volver al MainMenu
		print("Regresando al MainMenu")
		get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

# --- Configuración ---
func _save_config() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CONFIG_PATH)
	
	cfg.set_value(SECTION, "music_volume", int(music_slider.value))
	cfg.set_value(SECTION, "sfx_volume", int(sfx_slider.value))
	cfg.set_value(SECTION, "fullscreen", fullscreen_cb.button_pressed)
	
	cfg.save(CONFIG_PATH)
	print("Configuración guardada")

func _load_fullscreen_config() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		var fs = cfg.get_value(SECTION, "fullscreen", false)
		fullscreen_cb.button_pressed = bool(fs)
		
		# Aplicar fullscreen si estaba guardado
		if bool(fs):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		fullscreen_cb.button_pressed = false
