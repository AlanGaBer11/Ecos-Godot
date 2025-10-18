extends Node

# --- Variables exportadas ---
@export var music_volume: float = 1.0:
	set(value):
		music_volume = clamp(value, 0.0, 1.0)
		_apply_music_volume()

@export var sfx_volume: float = 0.8:
	set(value):
		sfx_volume = clamp(value, 0.0, 1.0)
		_apply_sfx_volume()

# --- Referencias internas ---
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

# --- Nombre de buses ---
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const CONFIG_PATH: String = "user://settings.cfg"
const SECTION: String = "audio"

# --- Ciclo de vida ---
func _ready() -> void:
	# Asignar buses a los players
	music_player.bus = MUSIC_BUS
	sfx_player.bus = SFX_BUS
	
	# IMPORTANTE: Cargar configuración guardada antes de aplicar volúmenes
	_load_saved_volumes()
	
	# Aplicar volúmenes iniciales
	_apply_music_volume()
	_apply_sfx_volume()
	
	print("AudioManager listo. Volúmenes iniciales -> Music:", music_volume, " SFX:", sfx_volume)

# --- Cargar volúmenes guardados ---
func _load_saved_volumes() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		var mv = cfg.get_value(SECTION, "music_volume", 100)
		var sv = cfg.get_value(SECTION, "sfx_volume", 80)
		
		# Actualizar las variables sin usar setters para evitar aplicar dos veces
		music_volume = float(mv) / 100.0
		sfx_volume = float(sv) / 100.0
		
		print("Volúmenes cargados desde archivo: Music=", music_volume, " SFX=", sfx_volume)
	else:
		print("No se encontró configuración guardada, usando valores por defecto")

# ========================
#  FUNCIONES PRINCIPALES
# ========================
func set_music_volume(v: float) -> void:
	music_volume = clamp(v, 0.0, 1.0)
	_apply_music_volume()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clamp(v, 0.0, 1.0)
	_apply_sfx_volume()

func _apply_music_volume() -> void:
	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if music_volume > 0.0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))
		AudioServer.set_bus_mute(bus_idx, false)
	else:
		# Mutear si el volumen es 0
		AudioServer.set_bus_mute(bus_idx, true)

func _apply_sfx_volume() -> void:
	var bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if sfx_volume > 0.0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))
		AudioServer.set_bus_mute(bus_idx, false)
	else:
		AudioServer.set_bus_mute(bus_idx, true)

# ========================
#  FUNCIONES DE MÚSICA
# ========================
func play_music(stream: AudioStream) -> void:
	if not music_player:
		push_warning("MusicPlayer no encontrado en AudioManager")
		return
	
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	if music_player and music_player.playing:
		music_player.stop()

# ========================
#  FUNCIONES DE EFECTOS
# ========================
func play_sfx(stream: AudioStream, parent: Node = null) -> void:
	# Crear un reproductor temporal para permitir múltiples SFX simultáneos
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = SFX_BUS
	
	if parent:
		parent.add_child(p)
	else:
		add_child(p)
	
	p.play()
	p.finished.connect(p.queue_free)
