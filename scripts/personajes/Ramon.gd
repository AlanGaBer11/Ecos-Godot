# Ramon.gd (VERSIÓN CORREGIDA)
class_name Ramon
extends "res://scripts/personajes/Personaje.gd"

@export var projectile_scene: PackedScene
@onready var spawn_point: Node2D = $ProyectilSpawn
@onready var attack_area: Area2D = $AttackArea
# NUEVO: Referencia a la barra de vida
@onready var barra_vida: BarraVidaEnemigo = $BarraVida

# Dirección / flags
var last_direction := "left"
var is_attacking := false
var current_attack_anim := ""
var special_attack_hit_done := false
var projectile_fired := false

# Disparo: separar duración de temporizador (FIX)
@export var shoot_cooldown_duration := 0.5
var shoot_timer := 0.0
var can_shoot := true

# Recuperación por daño: asegura desbloqueo aun si animación falla
@export var recovery_after_hit := 0.6
var recovery_timer := 0.0

# IA Variables
var ia_estado := "idle"
var ia_objetivo: Node2D = null
var ia_distancia_atacar := 100.0
var ia_distancia_disparar := 300.0
var ia_timer := 0.0
var ia_decision_cooldown := 0.2
var ia_ataque_especial_cooldown := 8.0
var ia_ataque_especial_timer := 0.0
var ia_ultimo_ataque := ""
var ia_contador_ataques := 0

func _ready() -> void:
	_velocidad_base = 400.0
	_fuerza_salto_base = 400.0
	_max_salud = 30
	_damage = 2
	es_jugador = false
	super._ready()
	
	# Attack area sólo se activa durante frames de golpe
	attack_area.monitoring = false
	attack_area.set_deferred("monitoring", false)
	
	if sprite and sprite.sprite_frames:
		for anim in ["attack", "jump_attack", "ranged_attack", "jump_ranged_attack", "special_attack"]:
			if sprite.sprite_frames.has_animation(anim):
				sprite.sprite_frames.set_animation_loop(anim, false)
	
	# NUEVO: Inicializar barra de vida
	if barra_vida:
		barra_vida.inicializar(_max_salud)
		# Las vidas iniciales las maneja Personaje._ready -> GameManager
		barra_vida.actualizar_vida(_salud_actual)
	
	call_deferred("_buscar_jugador")
	print("Ramon (Boss) inicializado con ", _max_salud, " HP")

func _buscar_jugador() -> void:
	for nodo in get_tree().get_nodes_in_group("personajes"):
		if nodo != self and nodo.has_method("get") and nodo.get("es_jugador") == true:
			ia_objetivo = nodo
			print("Ramon encontró al jugador: ", nodo.name)
			return
	print("⚠️ Ramon NO encontró jugador en grupo 'personajes'")

# Override del método recibir_danio para actualizar la barra y evitar quedarse bloqueado
func recibir_danio(cantidad: int, origen: Vector2 = Vector2.ZERO) -> void:
	# Llamar al padre (establece _is_taking_damage, play anim, etc.)
	super.recibir_danio(cantidad, origen)
	
	# Actualizar barra de vida
	if barra_vida:
		barra_vida.actualizar_vida(_salud_actual)
		barra_vida.actualizar_color_dinamico()
	
	# FIX: Asegurar que los flags de ataque se reseteen y hitbox se desactive
	is_attacking = false
	special_attack_hit_done = false
	projectile_fired = false
	attack_area.monitoring = false
	
	# Forzamos estado IA a chase (o idle si prefieres)
	ia_estado = "chase"
	
	# Iniciar temporizador de recuperación por si la animación "take_damage" no llegara a resetear _is_taking_damage
	recovery_timer = recovery_after_hit

# Manejo de señales de hitbox
func _on_attack_area_body_entered(body: Node) -> void:
	# Sólo aplicar daño si estábamos atacando y el objetivo coincide (precaución adicional)
	if is_attacking and body != self and body == ia_objetivo:
		aplicar_dano(body)

func _physics_process(delta: float) -> void:
	if not _esta_vivo:
		return
	
	# Llamar la física del padre (manejo de movimiento/escala/grav)
	super._physics_process(delta)
	
	# Actualizar timers de disparo
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			can_shoot = true
			shoot_timer = 0.0
	
	# Recovery timer: si la animación no acabó por alguna razón, desbloqueamos
	if _is_taking_damage:
		recovery_timer -= delta
		if recovery_timer <= 0.0:
			_is_taking_damage = false
			recovery_timer = 0.0
			# Si quedó en ataque, sacarlo
			is_attacking = false
			attack_area.monitoring = false
			sprite.play("idle")
	
	# Reducir timer del ataque especial
	if ia_ataque_especial_timer > 0:
		ia_ataque_especial_timer -= delta
	
	_controles_ia(delta)
	
	# Si está atacando o tomando daño, no re-ejecutar animaciones principales (se controlan en señales)
	if is_attacking or _is_taking_damage:
		# Aplicar una ligera desaceleración si fue knockback para que no quede velocidad infinita
		velocity.x = move_toward(velocity.x, 0, 1200 * delta)
		return
	
	# Animaciones estándar cuando no hay bloqueo
	if not is_on_floor():
		sprite.play("jump") if velocity.y < 0 else sprite.play("fall")
	else:
		if abs(velocity.x) > 1:
			sprite.play("run")
			last_direction = "left" if velocity.x < 0 else "right"
			sprite.flip_h = (last_direction == "left")
		else:
			sprite.play("idle")
			sprite.flip_h = (last_direction == "left")


# -------------------------
# IA (mejorada y segura)
# -------------------------
func _controles_ia(delta: float) -> void:
	# Si está atacando o recibiendo daño, no tomar decisiones
	if is_attacking or _is_taking_damage:
		return
	
	# Buscar objetivo válido
	if ia_objetivo == null or not is_instance_valid(ia_objetivo):
		_buscar_jugador()
		ia_estado = "idle"
		return
	
	ia_timer -= delta
	if ia_timer <= 0.0:
		ia_timer = ia_decision_cooldown
		_ia_tomar_decision()
	
	match ia_estado:
		"chase":
			_ia_perseguir()
		"retreat":
			_ia_retroceder()
		"attack":
			_ia_atacar()
		"shoot":
			_ia_disparar()
		"special_attack":
			_ia_ataque_especial()
		"idle":
			_ia_idle()

func _ia_tomar_decision() -> void:
	if ia_objetivo == null or not is_instance_valid(ia_objetivo):
		ia_estado = "idle"
		return
	
	# Distancia real y diferencia vertical
	var distancia = global_position.distance_to(ia_objetivo.global_position)
	var diff_y = abs(global_position.y - ia_objetivo.global_position.y)
	
	# Si el jugador está muy alto/bajo, preferir chase antes que atacar
	if diff_y > 120:
		ia_estado = "chase"
		return
	
	# Si está demasiado lejos para todo, patrulla/chase
	if distancia > ia_distancia_disparar * 1.2:
		ia_estado = "chase"
		return
	
	if distancia < ia_distancia_atacar:
		ia_contador_ataques += 1
		if ia_contador_ataques % 4 == 0:
			ia_estado = "retreat"
		elif ia_ataque_especial_timer <= 0 and randf() < 0.12:
			ia_estado = "special_attack"
			ia_ataque_especial_timer = ia_ataque_especial_cooldown
			ia_ultimo_ataque = "special"
		else:
			ia_estado = "attack"
			ia_ultimo_ataque = "attack"
	elif distancia < ia_distancia_disparar:
		# Preferir shoot si podemos, pero checar último ataque y dist vertical
		if can_shoot and (ia_ultimo_ataque == "attack" or randf() < 0.6):
			ia_estado = "shoot"
			ia_ultimo_ataque = "shoot"
		else:
			ia_estado = "chase"
	else:
		ia_estado = "chase"

func _ia_idle() -> void:
	velocity.x = move_toward(velocity.x, 0, _velocidad_base * 0.2)

func _ia_perseguir() -> void:
	if ia_objetivo == null or not is_instance_valid(ia_objetivo):
		return
	
	var direccion = sign(ia_objetivo.global_position.x - global_position.x)
	velocity.x = direccion * _velocidad_base * 0.9
	
	sprite.flip_h = (direccion < 0)
	last_direction = "left" if direccion < 0 else "right"
	
	# Saltar si hay diferencia vertical o obstáculo
	if is_on_floor():
		var diff_y = ia_objetivo.global_position.y - global_position.y
		if diff_y < -50 or _ia_hay_obstaculo():
			velocity.y = -_fuerza_salto_base

func _ia_retroceder() -> void:
	if ia_objetivo == null or not is_instance_valid(ia_objetivo):
		return
	
	var direccion = -sign(ia_objetivo.global_position.x - global_position.x)
	velocity.x = direccion * _velocidad_base * 0.7
	
	sprite.flip_h = (direccion > 0)
	last_direction = "right" if direccion > 0 else "left"

func _ia_atacar() -> void:
	if ia_objetivo == null or not is_instance_valid(ia_objetivo):
		return
	
	# Verificar distancia actual antes de iniciar ataque (abort si se alejó)
	var distancia = global_position.distance_to(ia_objetivo.global_position)
	if distancia > ia_distancia_atacar * 1.1:
		ia_estado = "chase"
		return
	
	var direccion = sign(ia_objetivo.global_position.x - global_position.x)
	velocity.x = direccion * _velocidad_base * 0.55
	
	sprite.flip_h = (direccion < 0)
	last_direction = "left" if direccion < 0 else "right"
	
	if not is_attacking:
		_atacar()

func _ia_disparar() -> void:
	if ia_objetivo == null or not is_instance_valid(ia_objetivo) or not can_shoot:
		ia_estado = "chase"
		return
	
	# Si jugador se alejó, cambiar a chase
	var distancia = global_position.distance_to(ia_objetivo.global_position)
	if distancia > ia_distancia_disparar * 1.05:
		ia_estado = "chase"
		return
	
	velocity.x = move_toward(velocity.x, 0, _velocidad_base * 0.7)
	
	var direccion = sign(ia_objetivo.global_position.x - global_position.x)
	sprite.flip_h = (direccion < 0)
	last_direction = "left" if direccion < 0 else "right"
	
	if not is_attacking:
		_disparar()

func _ia_ataque_especial() -> void:
	if ia_objetivo == null or not is_instance_valid(ia_objetivo):
		return
	
	# Abort si la distancia ya no es la adecuada
	var distancia = global_position.distance_to(ia_objetivo.global_position)
	if distancia > ia_distancia_atacar * 1.2:
		ia_estado = "chase"
		return
	
	velocity.x = 0
	var direccion = sign(ia_objetivo.global_position.x - global_position.x)
	sprite.flip_h = (direccion < 0)
	last_direction = "left" if direccion < 0 else "right"
	
	if not is_attacking:
		_ataque_especial()

func _ia_hay_obstaculo() -> bool:
	var space_state = get_world_2d().direct_space_state
	var direccion = 1 if not sprite.flip_h else -1
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(direccion * 60, 0)
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.size() > 0

# -------------------------
# ATAQUES (controlados)
# -------------------------
func _atacar() -> void:
	if is_attacking: return
	is_attacking = true
	can_shoot = false
	shoot_timer = shoot_cooldown_duration
	projectile_fired = false
	special_attack_hit_done = false
	current_attack_anim = "jump_attack" if not is_on_floor() else "attack"
	sprite.play(current_attack_anim)

func _ataque_especial() -> void:
	if is_attacking: return
	is_attacking = true
	can_shoot = false
	shoot_timer = max(shoot_timer, 1.0)
	special_attack_hit_done = false
	projectile_fired = false
	current_attack_anim = "special_attack"
	sprite.play(current_attack_anim)

func _disparar() -> void:
	if is_attacking: return
	is_attacking = true
	can_shoot = false
	shoot_timer = 0.5
	projectile_fired = false
	special_attack_hit_done = false
	current_attack_anim = "jump_ranged_attack" if not is_on_floor() else "ranged_attack"
	sprite.play(current_attack_anim)

# Realizar golpe: activamos hitbox sólo durante ventana corta.
func _realizar_golpe() -> void:
	# Se asegura que el área se apague si algo interrumpe
	attack_area.monitoring = true
	await get_tree().create_timer(0.15).timeout
	attack_area.monitoring = false

func _lanzar_proyectil() -> void:
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = spawn_point.global_position
		projectile.set_direction(-1 if sprite.flip_h else 1)

# -------------------------
# Señales de sprite (frames / finished)
# -------------------------
func _on_animated_sprite_2d_frame_changed() -> void:
	if not is_attacking:
		return
		
	var anim = sprite.animation
	var current_frame = sprite.frame
	
	# Proyectil en frame específico
	if anim in ["ranged_attack", "jump_ranged_attack"] and current_frame == 3 and not projectile_fired:
		_lanzar_proyectil()
		projectile_fired = true
	
	# Ventana de golpees
	if anim in ["attack", "jump_attack", "special_attack"]:
		if anim == "special_attack" and current_frame in [2,3,4] and not special_attack_hit_done:
			_realizar_golpe()
			special_attack_hit_done = true
		elif anim == "attack" and current_frame == 2:
			_realizar_golpe()
		elif anim == "jump_attack" and current_frame == 1:
			_realizar_golpe()

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite.animation:
		"attack", "jump_attack", "ranged_attack", "jump_ranged_attack", "special_attack":
			# Reset completo de flags al terminar ataque
			is_attacking = false
			can_shoot = true
			shoot_timer = 0.0
			special_attack_hit_done = false
			projectile_fired = false
			ia_estado = "chase"
			sprite.play("idle")
		"take_damage":
			# Si la animación de daño terminó, desbloqueamos
			_is_taking_damage = false
			recovery_timer = 0.0
			is_attacking = false
			attack_area.monitoring = false
			ia_estado = "chase"
			sprite.play("idle")

func morir() -> void:
	if not _esta_vivo:
		return

	_esta_vivo = false
	sprite.play("death")

	# Esperamos que acabe animación o 1 segundo máximo
	await get_tree().create_timer(1.0).timeout

	# Cargar escena de victoria
	var escena_ganaste = load("res://scenes/menus/Victoria.tscn").instantiate()
	get_tree().current_scene.add_child(escena_ganaste)

	print("🎉 Ganaste: Ramón ha sido derrotado")
