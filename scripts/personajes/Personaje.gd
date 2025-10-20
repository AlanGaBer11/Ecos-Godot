class_name Personaje
extends CharacterBody2D

# --------------------------------------------------------------------------
# ENCAPSULAMIENTO
# --------------------------------------------------------------------------
@export var _velocidad_base: float = 300.0    # Velocidad horizontal
@export var _fuerza_salto_base: float = 400.0 # Fuerza de salto
@export var _max_salud: int = 10              # Salud máxima
@export var _damage: int = 1                  # Daño base del personaje

var _salud_actual: int                         # Salud actual
var _saltos_disponibles: int = 2               # Para doble salto
var _gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _esta_vivo: bool = true                    # Estado del personaje

# --------------------------------------------------------------------------
# CICLO DE VIDA
# --------------------------------------------------------------------------
func _ready() -> void:
	_salud_actual = _max_salud

# --------------------------------------------------------------------------
# LÓGICA DE MOVIMIENTO BASE
# --------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not _esta_vivo:
		return

	# 1. Aplicar gravedad
	if not is_on_floor():
		velocity.y += _gravedad * delta
	else:
		_saltos_disponibles = 2 # Reinicia saltos al tocar el suelo

	# 2. Manejar movimiento horizontal (Input.get_axis devuelve -1..1)
	var direccion_x: float = Input.get_axis("ui_left", "ui_right")

	# Si hay entrada horizontal, velocidad directa; si no, desacelerar hacia 0
	if direccion_x != 0.0:
		velocity.x = direccion_x * _velocidad_base
	else:
		var desacel := _velocidad_base * 8.0 * delta
		velocity.x = move_toward(velocity.x, 0.0, desacel)

	# 3. Llamar salto (polimorfismo)
	saltar()

	# 4. Aplicar movimiento
	move_and_slide()

# --------------------------------------------------------------------------
# MÉTODOS POLIMÓRFICOS
# --------------------------------------------------------------------------
func saltar() -> void:
	# Usa la acción "ui_accept" para saltar (configurar en Input Map)
	if Input.is_action_just_pressed("ui_up"):
		if _saltos_disponibles > 0:
			velocity.y = -_fuerza_salto_base
			_saltos_disponibles -= 1

# --------------------------------------------------------------------------
# MÉTODOS PÚBLICOS
# --------------------------------------------------------------------------
func curar(cantidad: int) -> void:
	_salud_actual += cantidad
	if _salud_actual > _max_salud:
		_salud_actual = _max_salud
	print("Salud actualizada a: ", _salud_actual)

# --------------------------------------------------------------------------
# SISTEMA DE DAÑO
# --------------------------------------------------------------------------

# Aplica daño a otro objetivo si tiene el método recibir_danio
func aplicar_dano(objetivo: Node) -> void:
	if objetivo and objetivo.has_method("recibir_danio"):
		objetivo.recibir_danio(_damage)
		print(name, " infligió ", _damage, " de daño a ", objetivo.name)

# Recibe daño
func recibir_danio(cantidad: int) -> void:
	if not _esta_vivo:
		return

	_salud_actual -= cantidad
	print(name, " recibió ", cantidad, " de daño. Salud restante: ", _salud_actual)

	if _salud_actual <= 0:
		_salud_actual = 0
		morir()

# El personaje muere
func morir() -> void:
	if not _esta_vivo:
		return

	_esta_vivo = false
	print(name, " ha sido derrotado.")
	queue_free()
