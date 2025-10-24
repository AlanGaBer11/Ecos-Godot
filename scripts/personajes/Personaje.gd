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
var _saltos_maximos: int = 2                   #
var _gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _esta_vivo: bool = true                    # Estado del personaje
var _is_taking_damage: bool = false            # Nuevo: control de recibir daño
var _knockback_direction := 0                  # Dirección del retroceso (-1 ó 1)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# --------------------------------------------------------------------------
# CICLO DE VIDA
# --------------------------------------------------------------------------
func _ready() -> void:
	_salud_actual = _max_salud
	_saltos_maximos = _saltos_disponibles
	# Conecta la señal 
	if sprite:
		sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

# --------------------------------------------------------------------------
# LÓGICA DE MOVIMIENTO BASE
# --------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not _esta_vivo:
		return

	# 1. Aplicar gravedad (SIEMPRE, a menos que esté en el suelo)
	if not is_on_floor():
		velocity.y += _gravedad * delta
	else:
		# Solo reinicia saltos si no está recibiendo daño
		if not _is_taking_damage: 
			_saltos_disponibles = _saltos_maximos

	# 2. Lógica de movimiento (Horizontal)
	if _is_taking_damage:
		# Mientras recibe daño, solo aplica fricción al knockback
		velocity.x = move_toward(velocity.x, 0, delta * 800) 
	else:
		# Movimiento horizontal normal (controlado por el jugador)
		var direccion_x: float = Input.get_axis("ui_left", "ui_right")
		if direccion_x != 0.0:
			velocity.x = direccion_x * _velocidad_base
		else:
			var desacel := _velocidad_base * 8.0 * delta
			velocity.x = move_toward(velocity.x, 0.0, desacel)

		# 3. Salto (solo si no está recibiendo daño)
		saltar()

	# 4. Movimiento (UNA SOLA VEZ al final)
	move_and_slide()

# --------------------------------------------------------------------------
# MÉTODOS POLIMÓRFICOS
# --------------------------------------------------------------------------
func saltar() -> void:
	if Input.is_action_just_pressed("ui_up") and _saltos_disponibles > 0:
		velocity.y = -_fuerza_salto_base
		_saltos_disponibles -= 1

# --------------------------------------------------------------------------
# MÉTODOS PÚBLICOS
# --------------------------------------------------------------------------
func curar(cantidad: int) -> void:
	_salud_actual = min(_salud_actual + cantidad, _max_salud)
	print("Salud actualizada a: ", _salud_actual)

# --------------------------------------------------------------------------
# SISTEMA DE DAÑO
# --------------------------------------------------------------------------
# Aplica daño a otro objetivo
func aplicar_dano(objetivo: Node) -> void:
	if objetivo and objetivo.has_method("recibir_danio"):
		objetivo.recibir_danio(_damage, global_position)

func recibir_danio(cantidad: int, origen: Vector2 = Vector2.ZERO) -> void:
	if not _esta_vivo or _is_taking_damage:
		return

	_salud_actual -= cantidad
	print(name, " recibió ", cantidad, " de daño. Salud restante: ", _salud_actual)

	if _salud_actual > 0:
		_is_taking_damage = true
		_knockback_direction = -1 if origen.x > global_position.x else 1
		velocity.x = 300 * _knockback_direction
		velocity.y = 0

		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("take_damage"):
			sprite.sprite_frames.set_animation_loop("take_damage", false)
			sprite.play("take_damage")
	else:
		_salud_actual = 0
		morir()

func morir() -> void:
	if not _esta_vivo:
		return

	_esta_vivo = false
	print(name, " ha sido derrotado.")

	if sprite and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await get_tree().create_timer(sprite.sprite_frames.get_frame_count("death") / sprite.speed).timeout

	queue_free()
	
func _on_animation_finished() -> void:
	# Solo nos importa si la animación que terminó fue "take_damage"
	if sprite.animation == "take_damage":
		_is_taking_damage = false
		_knockback_direction = 0
		print(name, " terminó animación de daño")
