class_name Tobio
extends "res://scripts/personajes/Personaje.gd"

# -----------------------------
# EXPORTS Y ONREADY
# -----------------------------
@export var projectile_scene: PackedScene          # Escena del proyectil que dispara el personaje
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D   # Referencia al sprite animado
@onready var spawn_point: Node2D = $ProyectilSpawn          # Punto desde donde se lanza el proyectil

# -----------------------------
# ESTADOS DEL PERSONAJE
# -----------------------------
var last_direction: String = "right"  # Última dirección que miró el personaje
var can_shoot: bool = true            # Control de cooldown del disparo
var is_attacking: bool = false        # Si está realizando un ataque
var projectile_fired: bool = false    # Control de disparo para no disparar varias veces
var shoot_cooldown := 0.5             # Tiempo de espera entre disparos
var current_attack_anim := ""         # Animación actual de ataque

# -----------------------------
# ATAQUE DOBLE
# -----------------------------
var waiting_for_double := false       # Control de espera para detectar doble toque
var double_attack_time := 0.5         # Tiempo máximo para considerar doble toque
var last_attack_time := 0.0           # Momento del último ataque para detectar doble toque

# -----------------------------
# ATAQUE ESPECIAL (para controlar golpes múltiples)
# -----------------------------
var special_attack_hit_done := false  # Evita aplicar daño múltiple en special_attack

# -----------------------------
# READY
# -----------------------------
func _ready() -> void:
	_velocidad_base = 400.0            # Velocidad base del personaje
	_fuerza_salto_base = 450.0         # Fuerza de salto base


# -----------------------------
# PROCESO FÍSICO
# -----------------------------
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# -----------------------------
	# CONTROL DE DISPARO
	# -----------------------------
	if not can_shoot:
		shoot_cooldown -= delta
		if shoot_cooldown <= 0.0:
			can_shoot = true

	# -----------------------------
	# DETECCIÓN DE ATAQUE SIMPLE / DOBLE
	# -----------------------------
	if Input.is_action_just_pressed("ui_attack"):
		var now = Time.get_ticks_msec() / 1000.0    # Tiempo actual en segundos
		if now - last_attack_time < double_attack_time:
			# Si presionó rápido, ejecutar ataque doble
			waiting_for_double = false
			last_attack_time = 0.0
			_ataque_doble()
		else:
			# Si es el primer toque, ejecutar ataque básico
			last_attack_time = now
			_atacar()

	# -----------------------------
	# OTROS ATAQUES
	# -----------------------------
	if Input.is_action_just_pressed("ui_special_attack") and not is_attacking:
		_ataque_especial()

	if Input.is_action_just_pressed("ui_fire") and can_shoot and not is_attacking:
		_disparar()

	# -----------------------------
	# BLOQUEAR MOVIMIENTO DURANTE ATAQUE
	# -----------------------------
	if is_attacking:
		return   # No se permite mover ni cambiar animación mientras ataca

	# -----------------------------
	# ANIMACIONES NORMALES
	# -----------------------------
	if not is_on_floor():   # En aire
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
	else:                   # En el suelo
		if velocity.x != 0:
			sprite.play("run")
			last_direction = "left" if velocity.x < 0 else "right"
			sprite.flip_h = (last_direction == "left")
		else:
			sprite.play("idle")
			sprite.flip_h = (last_direction == "left")


# -----------------------------
# FUNCIONES DE ATAQUE
# -----------------------------
# Ataque básico
func _atacar() -> void:
	if is_attacking:
		return    # Evitar superposición de ataques

	is_attacking = true
	can_shoot = false
	shoot_cooldown = 0.4
	projectile_fired = false

	# Determinar animación según si está en aire o suelo
	if not is_on_floor() and sprite.sprite_frames.has_animation("jump_attack"):
		current_attack_anim = "jump_attack"
	else:
		current_attack_anim = "attack"

	# Reproducir animación
	if sprite.sprite_frames.has_animation(current_attack_anim):
		sprite.play(current_attack_anim)
	else:
		print("No existe la animación:", current_attack_anim)

# Ataque doble
func _ataque_doble() -> void:
	is_attacking = true
	can_shoot = false
	shoot_cooldown = 0.6
	projectile_fired = false

	current_attack_anim = "attack_2_hits"

	if sprite.sprite_frames.has_animation(current_attack_anim):
		sprite.play(current_attack_anim)
	else:
		print("No existe la animación:", current_attack_anim)

# Ataque especial
func _ataque_especial() -> void:
	if is_attacking:
		return

	is_attacking = true
	can_shoot = false
	shoot_cooldown = 1.0
	projectile_fired = false
	special_attack_hit_done = false

	current_attack_anim = "special_attack"

	if sprite.sprite_frames.has_animation(current_attack_anim):
		sprite.play(current_attack_anim)
	else:
		print("No existe la animación:", current_attack_anim)


# -----------------------------
# DISPARO
# -----------------------------
func _disparar() -> void:
	is_attacking = true
	can_shoot = false
	shoot_cooldown = 0.5
	projectile_fired = false

	if not is_on_floor() and sprite.sprite_frames.has_animation("jump_ranged_attack"):
		current_attack_anim = "jump_ranged_attack"
	else:
		current_attack_anim = "ranged_attack"

	if sprite.sprite_frames.has_animation(current_attack_anim):
		sprite.play(current_attack_anim)
	else:
		print("No existe la animación:", current_attack_anim)


# -----------------------------
# FRAME SYNC (Control de animaciones y efectos)
# -----------------------------
func _on_animated_sprite_2d_frame_changed() -> void:
	if not is_attacking:
		return

	var current_frame = sprite.frame
	var anim = sprite.animation

	if anim == current_attack_anim:
		# ----------------------------------------
		# ATAQUE A DISTANCIA (disparo en frame 3)
		# ----------------------------------------
		if anim == "ranged_attack" or anim == "jump_ranged_attack":
			if current_frame == 3 and not projectile_fired:
				_lanzar_proyectil()
				projectile_fired = true

		# ----------------------------------------
		# ATAQUES CUERPO A CUERPO
		# ----------------------------------------
		elif anim in ["attack", "jump_attack", "attack_2_hits", "special_attack"]:
			if anim == "special_attack":
				# Golpe en frames 2, 3 y 4
				if current_frame >= 2 and current_frame <= 4 and not special_attack_hit_done:
					_aplicar_dano()
					special_attack_hit_done = true
			else:
				# Golpe simple (frame 2)
				if current_frame == 2:
					_aplicar_dano()

		# ----------------------------------------
		# FINALIZAR ATAQUE (pequeña pausa)
		# ----------------------------------------
		if current_frame == sprite.sprite_frames.get_frame_count(anim) - 1:
			await get_tree().create_timer(0.05).timeout
			is_attacking = false
			special_attack_hit_done = false


# -----------------------------
# FUNCIONES AUXILIARES
# -----------------------------
func _aplicar_dano() -> void:
	print("¡Golpe ejecutado! (desde ", current_attack_anim, ")")
	# Aquí podrías detectar enemigos usando Area2D o RayCast2D

func _lanzar_proyectil() -> void:
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)

		if spawn_point:
			projectile.global_position = spawn_point.global_position
		else:
			projectile.global_position = global_position

		var dir = -1 if sprite.flip_h else 1
		projectile.set_direction(dir)
		print("Proyectil instanciado (desde ", current_attack_anim, ")")
