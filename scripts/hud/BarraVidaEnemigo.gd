# BarraVidaEnemigo.gd
class_name BarraVidaEnemigo
extends Control

# Configuración visual
@export var barra_ancho: float = 30.0
@export var barra_alto: float = 3.0
@export var offset_y: float = -100  # Distancia sobre el enemigo
@export var color_fondo: Color = Color(0.2, 0.2, 0.2, 0.8)  # Gris oscuro
@export var color_vida: Color = Color(0.8, 0.1, 0.1, 1.0)  # Rojo
@export var color_borde: Color = Color(0.1, 0.1, 0.1, 1.0)  # Negro
@export var grosor_borde: float = 1.0
@export var mostrar_siempre: bool = false  # Si es false, solo se muestra al recibir daño
@export var tiempo_visible: float = 3.0  # Tiempo que permanece visible después de recibir daño

# Variables internas
var vida_maxima: float = 100.0
var vida_actual: float = 100.0
var _timer_visibilidad: float = 0.0
var _esta_visible: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(barra_ancho, barra_alto)
	
	# Centrar la barra
	position.x = -barra_ancho / 2.0
	position.y = offset_y
	
	# Configurar visibilidad inicial
	if mostrar_siempre:
		_esta_visible = true
		modulate.a = 1.0
	else:
		_esta_visible = false
		modulate.a = 0.0

func _process(delta: float) -> void:
	if not mostrar_siempre and _esta_visible:
		_timer_visibilidad -= delta
		
		if _timer_visibilidad <= 0:
			# Fade out
			modulate.a = max(0, modulate.a - delta * 2.0)
			if modulate.a <= 0:
				_esta_visible = false
	
	# Forzar redibujado
	queue_redraw()

func _draw() -> void:
	# Calcular porcentaje de vida
	var porcentaje = vida_actual / vida_maxima if vida_maxima > 0 else 0
	porcentaje = clamp(porcentaje, 0.0, 1.0)
	
	# Dimensiones
	var rect_fondo = Rect2(Vector2.ZERO, Vector2(barra_ancho, barra_alto))
	var rect_vida = Rect2(Vector2.ZERO, Vector2(barra_ancho * porcentaje, barra_alto))
	
	# Dibujar borde
	draw_rect(rect_fondo.grow(grosor_borde), color_borde)
	
	# Dibujar fondo
	draw_rect(rect_fondo, color_fondo)
	
	# Dibujar vida actual
	draw_rect(rect_vida, color_vida)

# Inicializar con la vida máxima del enemigo
func inicializar(vida_max: float) -> void:
	vida_maxima = vida_max
	vida_actual = vida_max
	queue_redraw()

# Actualizar la vida mostrada
func actualizar_vida(nueva_vida: float) -> void:
	vida_actual = clamp(nueva_vida, 0, vida_maxima)
	
	# Mostrar la barra temporalmente
	if not mostrar_siempre:
		_esta_visible = true
		_timer_visibilidad = tiempo_visible
		modulate.a = 1.0
	
	queue_redraw()

# Cambiar el color de la barra según el porcentaje de vida
func actualizar_color_dinamico() -> void:
	var porcentaje = vida_actual / vida_maxima if vida_maxima > 0 else 0
	
	if porcentaje > 0.6:
		color_vida = Color(0.2, 0.8, 0.2)  # Verde
	elif porcentaje > 0.3:
		color_vida = Color(0.9, 0.7, 0.1)  # Amarillo
	else:
		color_vida = Color(0.8, 0.1, 0.1)  # Rojo
