# Este script representa la CLASE BASE 'Personaje' (Abstracción).
extends CharacterBody2D

# --------------------------------------------------------------------------
# ENCAPSULAMIENTO:para indicar que son internas (privadas).
# --------------------------------------------------------------------------
@export var _velocidad_base: float = 300.0 # Velocidad horizontal 
@export var _fuerza_salto_base: float = 400.0 # Fuerza de salto
@export var _max_salud: int = 100 # Salud máxima

var _salud_actual: int = _max_salud # Salud actual
var _saltos_disponibles: int = 2 # Para el doble salto (Metroidvania)
var _gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# --------------------------------------------------------------------------
# LÓGICA DE MOVIMIENTO 
# --------------------------------------------------------------------------
func _physics_process(delta):
	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y += _gravedad * delta
	else:
		_saltos_disponibles = 2 # Reiniciar saltos al tocar el suelo
	
	# 2. Manejar entrada horizontal
	var direccion_x = Input.get_axis("ui_left", "ui_right")

	if direccion_x:
		velocity.x = direccion_x * _velocidad_base
	else:
		velocity.x = move_toward(velocity.x, 0, _velocidad_base)

	# 3. Llamar al método de salto (Polimorfismo)
	saltar()
	
	move_and_slide()

# --------------------------------------------------------------------------
# MÉTODOS PÚBLICOS 
# --------------------------------------------------------------------------

# Método polimórfico para el salto. Las clases hijas pueden sobrescribirlo.
func saltar():
	if Input.is_action_just_pressed("ui_accept"):
		if _saltos_disponibles > 0:
			velocity.y = -_fuerza_salto_base
			_saltos_disponibles -= 1

# Método para recibir curación (Encapsulamiento controlado)
func curar(cantidad: int):
	_salud_actual += cantidad
	if _salud_actual > _max_salud:
		_salud_actual = _max_salud
	print("Salud actualizada a: ", _salud_actual)
