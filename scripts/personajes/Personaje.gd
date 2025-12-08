# Personaje.gd
class_name Personaje
extends CharacterBody2D

# NUEVA SEÑAL para comunicar cambios de vida
signal vida_cambio(vida_actual: int, vida_maxima: int)

# --------------------------------------------------------------------------
# ENCAPSULAMIENTO
# --------------------------------------------------------------------------
@export var _velocidad_base: float = 300.0
@export var _fuerza_salto_base: float = 400.0
@export var _max_salud: int = 10
@export var _damage: int = 1
@export var es_jugador: bool = true

var _salud_actual: int
var _saltos_disponibles: int = 2
var _saltos_maximos: int = 2
var _gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _esta_vivo: bool = true
var _is_taking_damage: bool = false
var _knockback_direction := 0

# -------------------------------
# SISTEMA DE ESCALERAS
# -------------------------------
var en_escalera: bool = false
var puede_escalar: bool = false
@export var velocidad_escalera: float = 150.0


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var death_screen_scene = preload("res://scenes/menus/DeathScreen.tscn")

# --------------------------------------------------------------------------
# CICLO DE VIDA
# --------------------------------------------------------------------------
func _ready() -> void:
	# NUEVO: Pasar el nombre del personaje al inicializar
	GameManager.inicializar_vida(_max_salud, name)  # Pasar "Tobio" o "Manchas"
	
	# Cargar vida guardada del GameManager
	if GameManager.obtener_vida() > 0:
		_salud_actual = GameManager.obtener_vida()
	else:
		_salud_actual = _max_salud
	
	_saltos_maximos = _saltos_disponibles
	if sprite:
		sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	# Emitir vida inicial
	vida_cambio.emit(_salud_actual, _max_salud)
	print(name, " iniciado con vida: ", _salud_actual, "/", _max_salud)
	print(name, " iniciado con vida: ", _salud_actual, "/", _max_salud)

# --------------------------------------------------------------------------
# LÓGICA DE MOVIMIENTO BASE
# --------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not _esta_vivo:
		return

	# 1. Aplicar gravedad
	# SISTEMA DE ESCALERAS
	manejar_escalera(delta)

	if not en_escalera:
		# 1. Aplicar gravedad solo si NO está escalando
		aplicar_gravedad(delta)
	else:
		# Si escala, sin saltos y sin gravedad
		velocity.y = velocity.y
		_saltos_disponibles = _saltos_maximos

	# 2. Movimiento y salto (solo si es jugador)
	if es_jugador and not _is_taking_damage:
		manejar_movimiento(delta)
		manejar_salto()

	# 3. Mover personaje
	move_and_slide()

func aplicar_gravedad(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravedad * delta
	else:
		if not _is_taking_damage:
			_saltos_disponibles = _saltos_maximos

func manejar_movimiento(delta: float) -> void:
	if _is_taking_damage:
		velocity.x = move_toward(velocity.x, 0, delta * 800)
	else:
		var direccion_x: float = Input.get_axis("ui_left", "ui_right")
		if direccion_x != 0.0:
			velocity.x = direccion_x * _velocidad_base
		else:
			var desacel := _velocidad_base * 8.0 * delta
			velocity.x = move_toward(velocity.x, 0.0, desacel)

func manejar_salto() -> void:
	saltar()

# --------------------------------------------------------------------------
# MÉTODOS POLIMÓRFICOS
# --------------------------------------------------------------------------
func saltar() -> void:
	if  en_escalera: # No salta mientras escala
		return
		
	if Input.is_action_just_pressed("ui_jump") and _saltos_disponibles > 0:
		velocity.y = -_fuerza_salto_base
		_saltos_disponibles -= 1

# --------------------------------------------------------------------------
# MÉTODOS PÚBLICOS
# --------------------------------------------------------------------------
func curar(cantidad: int) -> void:
	_salud_actual = min(_salud_actual + cantidad, _max_salud)
	print("Salud actualizada a: ", _salud_actual)
	# NUEVO: Emitir cambio de vida
	vida_cambio.emit(_salud_actual, _max_salud)

# NUEVO: Getter para la salud actual (para UI)
func get_salud_actual() -> int:
	return _salud_actual

# NUEVO: Getter para la salud máxima (para UI)
func get_max_salud() -> int:
	return _max_salud

# --------------------------------------------------------------------------
# SISTEMA DE DAÑO
# --------------------------------------------------------------------------
func aplicar_dano(objetivo: Node) -> void:
	
	if objetivo and objetivo.has_method("recibir_danio"):
		objetivo.recibir_danio(_damage, global_position)

func recibir_danio(cantidad: int, origen: Vector2 = Vector2.ZERO) -> void:
	if not _esta_vivo or _is_taking_damage:
		return

	_salud_actual -= cantidad
	_salud_actual = clamp(_salud_actual, 0, _max_salud)
	print(name, " recibió ", cantidad, " de daño. Salud restante: ", _salud_actual)
	
	# Guardar vida en GameManager
	GameManager.guardar_vida(_salud_actual)
	
	# NUEVO: Emitir cambio de vida
	vida_cambio.emit(_salud_actual, _max_salud)

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
	
	# Resetear vida en GameManager
	GameManager.resetear_vida()
	
	# Desactivar físicas y controles
	set_physics_process(false)
	set_process_input(false)

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.sprite_frames.set_animation_loop("death", false)
		sprite.play("death")
		# Calcular duración basándose en frames y FPS de la animación
		var frame_count = sprite.sprite_frames.get_frame_count("death")
		var fps = sprite.sprite_frames.get_animation_speed("death")
		var duration = frame_count / fps if fps > 0 else 1.0
		await get_tree().create_timer(duration).timeout
	else:
		# Si no hay animación de muerte, esperar un momento
		await get_tree().create_timer(0.5).timeout
	
	# Mostrar pantalla de muerte
	var death_screen = death_screen_scene.instantiate()
	get_tree().current_scene.add_child(death_screen)
	
	# Pausar el juego
	get_tree().paused = true
	death_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ocultar el personaje en lugar de eliminarlo
	hide()

func _on_animation_finished() -> void:
	# Solo nos importa si la animación que terminó fue "take_damage"
	if sprite.animation == "take_damage":
		_is_taking_damage = false
		_knockback_direction = 0
		print(name, " terminó animación de daño")


# ======================================================================
# SISTEMA DE ESCALERAS
# ======================================================================

func entrar_escalera() -> void:
	puede_escalar = true

func salir_escalera() -> void:
	puede_escalar = false
	en_escalera = false

func manejar_escalera(delta: float) -> void:
	if not puede_escalar:
		en_escalera = false
		return

	var subir = Input.is_action_pressed("ui_up")
	var bajar = Input.is_action_pressed("ui_down")

	# Detectar si estamos intentando escalar
	if subir or bajar:
		en_escalera = true

	# Si estamos escalando, anulamos gravedad
	if en_escalera:
		velocity.y = 0

		if subir:
			velocity.y = -velocidad_escalera
		elif bajar:
			velocity.y = velocidad_escalera
		else:
			velocity.y = 0

		# Animación CLIMB
		if sprite.animation != "climb":
			sprite.play("climb")
	else:
		# Si no se presiona subir/bajar, salir de escalera si no hay overlap
		if not puede_escalar:
			en_escalera = false
