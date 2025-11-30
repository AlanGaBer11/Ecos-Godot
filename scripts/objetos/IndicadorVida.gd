# IndicadorVida.gd
class_name IndicadorVida
extends HBoxContainer

# Rutas a los sprites de corazones
@export var sprite_heart: Texture2D  # heart.png
@export var sprite_background: Texture2D  # background.png
@export var sprite_border: Texture2D  # border.png (opcional)

# Configuración visual
@export var corazon_size: Vector2 = Vector2(32, 32)
@export var spacing: int = 4

var vida_maxima: int = 0
var vida_actual: int = 0
var corazones: Array[TextureRect] = []

func _ready() -> void:
	add_theme_constant_override("separation", spacing)

# Inicializa el indicador con la vida máxima
func inicializar(vida_max: int) -> void:
	vida_maxima = vida_max
	vida_actual = vida_max
	_crear_corazones()

# Crea los contenedores de corazones
func _crear_corazones() -> void:
	# Limpiar corazones existentes
	for corazon in corazones:
		corazon.queue_free()
	corazones.clear()
	
	# Crear nuevos corazones
	for i in range(vida_maxima):
		var corazon_container = TextureRect.new()
		corazon_container.texture = sprite_heart
		corazon_container.custom_minimum_size = corazon_size
		corazon_container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		corazon_container.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		add_child(corazon_container)
		corazones.append(corazon_container)

# Actualiza la visualización de vida
func actualizar_vida(nueva_vida: int) -> void:
	vida_actual = clamp(nueva_vida, 0, vida_maxima)
	_actualizar_corazones()

# Actualiza la textura de cada corazón
func _actualizar_corazones() -> void:
	for i in range(corazones.size()):
		if i < vida_actual:
			# Corazón lleno
			corazones[i].texture = sprite_heart
			corazones[i].modulate = Color.WHITE
		else:
			# Corazón vacío (background)
			corazones[i].texture = sprite_background
			corazones[i].modulate = Color(1, 1, 1, 0.5)  # Más transparente

# Obtiene la vida actual
func get_vida_actual() -> int:
	return vida_actual

# Obtiene la vida máxima
func get_vida_maxima() -> int:
	return vida_maxima
