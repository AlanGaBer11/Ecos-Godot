class_name Ramon
extends "res://scripts/personajes/Personaje.gd"

@export var projectile_scene: PackedScene
@onready var spawn_point: Node2D = $ProyectilSpawn
@onready var attack_area: Area2D = $AttackArea

var last_direction := "left"
var is_attacking := false
var current_attack_anim := ""
var special_attack_hit_done := false
var projectile_fired := false
var can_shoot := true
var shoot_cooldown := 0.5

# IA Variables
var ia_estado := "idle"
var ia_objetivo: Node2D = null  # El jugador
var ia_distancia_atacar := 100.0
var ia_distancia_disparar := 300.0
var ia_timer := 0.0
var ia_decision_cooldown := 0.5  # Más rápido para reaccionar mejor
var ia_ataque_especial_cooldown := 8.0
var ia_ataque_especial_timer := 0.0
var ia_ultimo_ataque := ""  # Para no repetir el mismo ataque
var ia_contador_ataques := 0  # Contador para variar ataques

func _ready() -> void:
	_velocidad_base = 400.0
	_fuerza_salto_base = 400.0
	_max_salud = 30
	_damage = 2
	es_jugador = false
	super._ready()
	
	# NO conectar señales - ya están conectadas en el editor
	attack_area.monitoring = false
	
	# Desactivar loop en animaciones de ataque
	if sprite and sprite.sprite_frames:
		for anim in ["attack", "jump_attack", "ranged_attack", "jump_ranged_attack", "special_attack"]:
			if sprite.sprite_frames.has_animation(anim):
				sprite.sprite_frames.set_animation_loop(anim, false)
				print("Loop desactivado para: ", anim)
	
	# Buscar al jugador
	call_deferred("_buscar_jugador")
	print("Ramon (Boss) inicializado")

func _buscar_jugador() -> void:
	# Buscar el personaje que es jugador
	for nodo in get_tree().get_nodes_in_group("personajes"):
		if nodo != self and nodo.has_method("get") and nodo.get("es_jugador") == true:
			ia_objetivo = nodo
			print("Ramon encontró al jugador: ", nodo.name)
			return
	print("⚠️ Ramon NO encontró jugador en grupo 'personajes'")

func _on_attack_area_body_entered(body: Node) -> void:
	if is_attacking and body != self and body == ia_objetivo:
		aplicar_dano(body)

func _physics_process(delta: float) -> void:
	if not _esta_vivo:
		return
	
	# Gravedad del padre
	super._physics_process(delta)
	
	# Cooldown de disparo
	if not can_shoot:
		shoot_cooldown -= delta
		if shoot_cooldown <= 0.0:
			can_shoot = true
	
	# Cooldown de ataque especial
	if ia_ataque_especial_timer > 0:
		ia_ataque_especial_timer -= delta
	
	# ========================================
	# CONTROL DE LA IA
	# ========================================
	_controles_ia(delta)
	
	# Bloquear movimiento durante ataque o daño
	if is_attacking or _is_taking_damage:
		return
	
	# Animaciones normales
	if not is_on_floor():
		sprite.play("jump") if velocity.y < 0 else sprite.play("fall")
	else:
		if velocity.x != 0:
			sprite.play("run")
			last_direction = "left" if velocity.x < 0 else "right"
			sprite.flip_h = (last_direction == "left")
		else:
			sprite.play("idle")
			sprite.flip_h = (last_direction == "left")

# ========================================
# CONTROLES DE LA IA
# ========================================
func _controles_ia(delta: float) -> void:
	if is_attacking or _is_taking_damage:
		return
	
	# Buscar jugador si no tiene objetivo
	if ia_objetivo == null or not is_instance_valid(ia_objetivo):
		_buscar_jugador()
		ia_estado = "idle"
		return
	
	# Timer para tomar decisiones
	ia_timer -= delta
	if ia_timer <= 0.0:
		ia_timer = ia_decision_cooldown
		_ia_tomar_decision()
	
	# Ejecutar comportamiento según estado
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
	if ia_objetivo == null:
		ia_estado = "idle"
		return
	
	var distancia = global_position.distance_to(ia_objetivo.global_position)
	
	# Decidir qué hacer según distancia al jugador
	if distancia < ia_distancia_atacar:
		ia_contador_ataques += 1
		
		# Variar entre retroceder y atacar para no estar siempre encima
		if ia_contador_ataques % 4 == 0:
			# Cada 4 decisiones, retroceder
			ia_estado = "retreat"
			print("🔙 Ramon retrocede")
		# Usar ataque especial ocasionalmente (15% de probabilidad si está disponible)
		elif ia_ataque_especial_timer <= 0 and randf() < 0.15:
			ia_estado = "special_attack"
			ia_ataque_especial_timer = ia_ataque_especial_cooldown
			ia_ultimo_ataque = "special"
			print("🌟 Ramon decide usar ataque especial")
		else:
			# Ataque cuerpo a cuerpo normal
			ia_estado = "attack"
			ia_ultimo_ataque = "attack"
	elif distancia < ia_distancia_disparar:
		# En rango medio, alternar entre acercarse y disparar
		if can_shoot and (ia_ultimo_ataque == "attack" or randf() < 0.6):
			ia_estado = "shoot"
			ia_ultimo_ataque = "shoot"
		else:
			ia_estado = "chase"
			print("🏃 Ramon persigue al jugador")
	else:
		# Muy lejos, perseguir
		ia_estado = "chase"
		print("🏃 Ramon persigue al jugador")

func _ia_idle() -> void:
	velocity.x = move_toward(velocity.x, 0, _velocidad_base * 0.1)

func _ia_perseguir() -> void:
	if ia_objetivo == null:
		return
	
	# Moverse hacia el jugador
	var direccion = sign(ia_objetivo.global_position.x - global_position.x)
	velocity.x = direccion * _velocidad_base
	
	# Mirar hacia el jugador
	sprite.flip_h = (direccion < 0)
	last_direction = "left" if direccion < 0 else "right"
	
	# Saltar si hay obstáculo o el jugador está arriba
	if is_on_floor():
		var diff_y = ia_objetivo.global_position.y - global_position.y
		if diff_y < -50 or _ia_hay_obstaculo():
			velocity.y = -_fuerza_salto_base

func _ia_retroceder() -> void:
	if ia_objetivo == null:
		return
	
	# Alejarse del jugador
	var direccion = -sign(ia_objetivo.global_position.x - global_position.x)
	velocity.x = direccion * _velocidad_base * 0.7
	
	# Seguir mirando al jugador
	sprite.flip_h = (direccion > 0)  # Invertido porque va hacia atrás
	last_direction = "right" if direccion > 0 else "left"

func _ia_atacar() -> void:
	if ia_objetivo == null:
		return
	
	# Moverse hacia el jugador
	var direccion = sign(ia_objetivo.global_position.x - global_position.x)
	velocity.x = direccion * _velocidad_base * 0.6
	
	# Mirar hacia el jugador
	sprite.flip_h = (direccion < 0)
	last_direction = "left" if direccion < 0 else "right"
	
	# Atacar
	if not is_attacking:
		_atacar()

func _ia_disparar() -> void:
	if ia_objetivo == null or not can_shoot:
		return
	
	# Detenerse para disparar
	velocity.x = move_toward(velocity.x, 0, _velocidad_base * 0.5)
	
	# Mirar hacia el jugador
	var direccion = sign(ia_objetivo.global_position.x - global_position.x)
	sprite.flip_h = (direccion < 0)
	last_direction = "left" if direccion < 0 else "right"
	
	# Disparar
	if not is_attacking:
		_disparar()

func _ia_ataque_especial() -> void:
	if ia_objetivo == null:
		return
	
	# Detenerse y mirar al jugador
	velocity.x = 0
	var direccion = sign(ia_objetivo.global_position.x - global_position.x)
	sprite.flip_h = (direccion < 0)
	last_direction = "left" if direccion < 0 else "right"
	
	# Ejecutar ataque especial
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

# -----------------------------
# ATAQUES
# -----------------------------
func _atacar() -> void:
	if is_attacking: return
	is_attacking = true
	can_shoot = false
	shoot_cooldown = 0.4
	projectile_fired = false
	current_attack_anim = "jump_attack" if not is_on_floor() else "attack"
	sprite.play(current_attack_anim)

func _ataque_especial() -> void:
	if is_attacking: return
	is_attacking = true
	can_shoot = false
	shoot_cooldown = 1.0
	special_attack_hit_done = false
	current_attack_anim = "special_attack"
	sprite.play(current_attack_anim)

func _disparar() -> void:
	if is_attacking: return
	is_attacking = true
	can_shoot = false
	shoot_cooldown = 0.5
	projectile_fired = false
	current_attack_anim = "jump_ranged_attack" if not is_on_floor() else "ranged_attack"
	sprite.play(current_attack_anim)

func _realizar_golpe() -> void:
	attack_area.monitoring = true
	await get_tree().create_timer(0.15).timeout
	attack_area.monitoring = false

func _lanzar_proyectil() -> void:
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = spawn_point.global_position
		projectile.set_direction(-1 if sprite.flip_h else 1)

func _on_animated_sprite_2d_frame_changed() -> void:
	if not is_attacking:
		return
		
	var anim = sprite.animation
	var current_frame = sprite.frame
	
	# Proyectiles
	if anim in ["ranged_attack", "jump_ranged_attack"] and current_frame == 3 and not projectile_fired:
		_lanzar_proyectil()
		projectile_fired = true
	
	# Ataques cuerpo a cuerpo
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
			is_attacking = false
			can_shoot = true
			ia_estado = "chase"
			sprite.play("idle")
		"take_damage":
			_is_taking_damage = false
			ia_estado = "chase"
			sprite.play("idle")
