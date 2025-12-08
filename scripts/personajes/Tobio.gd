# Tobio.gd
class_name Tobio
extends "res://scripts/personajes/Personaje.gd"

@export var projectile_scene: PackedScene
@onready var spawn_point: Node2D = $ProyectilSpawn
@onready var attack_area: Area2D = $AttackArea

var last_direction := "right"
var is_attacking := false
var current_attack_anim := ""
var special_attack_hit_done := false
var projectile_fired := false
var can_shoot := true
var shoot_cooldown := 0.5

func _ready() -> void:
	es_jugador = true
	_velocidad_base = 350.0
	_fuerza_salto_base = 430.0
	_max_salud = 10
	_damage = 1
	super._ready()
	
	attack_area.monitoring = false
	
	print("Tobio iniciado - es_jugador: ", es_jugador)

func _on_attack_area_body_entered(body: Node) -> void:	
	if is_attacking and body != self:
		aplicar_dano(body)

func _physics_process(delta: float) -> void:
	if not _esta_vivo:
		return
	
	super._physics_process(delta)
	
	if not can_shoot:
		shoot_cooldown -= delta
		if shoot_cooldown <= 0.0:
			can_shoot = true
	
	if not is_attacking and not _is_taking_damage:
		if Input.is_action_just_pressed("ui_attack"):
			_atacar()
		elif Input.is_action_just_pressed("ui_special_attack"):
			_ataque_especial()
		elif Input.is_action_just_pressed("ui_fire") and can_shoot:
			_disparar()
	
	# IMPORTANTE: No manejar animaciones si está atacando o recibiendo daño
	if is_attacking or _is_taking_damage:
		return
	
	# NUEVO: Verificar primero si está escalando
	if en_escalera:
		# La animación "climb" ya se maneja en Personaje.gd
		# Solo actualizamos la dirección del sprite si se mueve horizontalmente
		if velocity.x != 0:
			last_direction = "left" if velocity.x < 0 else "right"
			sprite.flip_h = (last_direction == "left")
		return  # Salir para no ejecutar las animaciones de abajo
	
	# Animaciones normales (solo si NO está escalando)
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
	current_attack_anim = "jump_ranged_attack" if not is_on_floor() else "ranged_attack"
	sprite.play(current_attack_anim)

func _realizar_golpe() -> void:
	attack_area.monitoring = true
	await get_tree().create_timer(0.1).timeout
	attack_area.monitoring = false

func _lanzar_proyectil() -> void:
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = spawn_point.global_position
		projectile.set_direction(-1 if sprite.flip_h else 1)

# -----------------------------
# FRAME CHANGE ANIM SYNC
# -----------------------------
func _on_animated_sprite_2d_frame_changed() -> void:
	var anim = sprite.animation
	var current_frame = sprite.frame
	
	if anim in ["ranged_attack", "jump_ranged_attack"] and current_frame == 3 and not projectile_fired:
		_lanzar_proyectil()
		projectile_fired = true
	elif anim in ["attack", "jump_attack", "special_attack"]:
		if anim == "special_attack" and current_frame in [2,3,4] and not special_attack_hit_done:
			_realizar_golpe()
			special_attack_hit_done = true
		elif anim == "attack" and current_frame == 2:
			_realizar_golpe()
		elif anim == "jump_attack" and current_frame == 1:
			_realizar_golpe()
	
	if anim in ["attack","jump_attack","ranged_attack", "jump_ranged_attack", "special_attack"] and current_frame == sprite.sprite_frames.get_frame_count(anim) - 1:
		await get_tree().create_timer(0.05).timeout
		is_attacking = false
		special_attack_hit_done = false
		projectile_fired = false
		can_shoot = true
