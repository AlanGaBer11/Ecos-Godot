# FPSCounter.gd
class_name FPSCounter
extends Label

# Configuración
@export var mostrar_al_inicio: bool = false  # false para producción, true para desarrollo
@export var tecla_toggle: String = "ui_debug_fps"  # Configura esta acción en Input Map
@export var color_bueno: Color = Color.GREEN  # 60+ FPS
@export var color_medio: Color = Color.YELLOW  # 30-59 FPS
@export var color_malo: Color = Color.RED  # <30 FPS
@export var mostrar_info_extra: bool = true  # Mostrar más detalles técnicos

# Variables internas
var _visible_fps: bool = false
var _update_timer: float = 0.0
var _update_interval: float = 0.1  # Actualizar cada 0.1 segundos

func _ready() -> void:
	_visible_fps = mostrar_al_inicio
	visible = _visible_fps
	
	# Configuración visual por defecto
	if not custom_minimum_size.x:
		custom_minimum_size = Vector2(150, 0)
	
	# Estilo de fuente (opcional, ajusta según tu fuente)
	add_theme_font_size_override("font_size", 14)

func _process(delta: float) -> void:
	# Toggle de visibilidad
	if Input.is_action_just_pressed(tecla_toggle):
		_visible_fps = not _visible_fps
		visible = _visible_fps
	
	if not _visible_fps:
		return
	
	# Actualizar contador
	_update_timer += delta
	if _update_timer >= _update_interval:
		_update_timer = 0.0
		_actualizar_fps()

func _actualizar_fps() -> void:
	var fps = Engine.get_frames_per_second()
	
	# Cambiar color según rendimiento
	if fps >= 60:
		modulate = color_bueno
	elif fps >= 30:
		modulate = color_medio
	else:
		modulate = color_malo
	
	# Texto a mostrar
	if mostrar_info_extra:
		var memoria_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
		text = "FPS: %d\nMemoria: %.1f MB\nNodos: %d" % [
			fps,
			memoria_mb,
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		]
	else:
		text = "FPS: %d" % fps

# Métodos públicos para controlar desde código
func mostrar_fps() -> void:
	_visible_fps = true
	visible = true

func ocultar_fps() -> void:
	_visible_fps = false
	visible = false

func toggle_fps() -> void:
	_visible_fps = not _visible_fps
	visible = _visible_fps
