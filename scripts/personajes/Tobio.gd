class_name Tobio
extends "res://scripts/personajes/Personaje.gd"

@export var projectile_scene: PackedScene
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_point: Node2D = $ProyectilSpawn
@onready var attack_area: Area2D = $AttackArea   # <- Area2D para detectar golpes

# -----------------------------
# ESTADOS DEL PERSONAJE
# -----------------------------
var last_direction: String = "right"
var can_shoot: bool = true
var is_attacking: bool = false
var projectile_fired: bool = false
var shoot_cooldown := 0.5
var current_attack_anim := ""
var special_attack_hit_done := false

# -----------------------------
# AJUSTES ÚNICOS DE TOBIO
# -----------------------------
func _ready() -> void:
	_velocidad_base = 480.0    # Más rápido
	_fuerza_salto_base = 460.0
	_max_salud = 10
	_damage = 1                 # Ataque débil
	super._ready()
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))

func _on_attack_area_body_entered(body: Node) -> void:
	if is_attacking:
		aplicar_dano(body)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if not can_shoot:
		shoot_cooldown -= delta
		if shoot_cooldown <= 0.0:
			can_shoot = true

	if Input.is_action_just_pressed("ui_attack"):
		_atacar()
	if Input.is_action_just_pressed("ui_special_attack") and not is_attacking:
		_ataque_especial()
	if Input.is_action_just_pressed("ui_fire") and can_shoot and not is_attacking:
		_disparar()

	if is_attacking:
		return

	# Animaciones
	if not is_on_floor():
		sprite.play("jump") if velocity.y < 0 else sprite.play("fall")
		sprite.flip_h = velocity.x < 0 if velocity.x != 0 else sprite.flip_h
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
	if is_attacking:
		return
	is_attacking = true
	can_shoot = false
	shoot_cooldown = 0.4
	projectile_fired = false
	current_attack_anim = "attack"
	sprite.play(current_attack_anim)

func _ataque_especial() -> void:
	if is_attacking:
		return
	is_attacking = true
	can_shoot = false
	shoot_cooldown = 1.0
	projectile_fired = false
	special_attack_hit_done = false
	current_attack_anim = "special_attack"
	sprite.play(current_attack_anim)

func _disparar() -> void:
	is_attacking = true
	can_shoot = false
	shoot_cooldown = 0.5
	projectile_fired = false
	current_attack_anim = "ranged_attack"
	sprite.play(current_attack_anim)

# -----------------------------
# EVENTOS DE ANIMACIÓN
# -----------------------------
func _on_animated_sprite_2d_frame_changed() -> void:
	if not is_attacking:
		return

	var current_frame = sprite.frame
	var anim = sprite.animation

	if anim in ["ranged_attack"]:
		if current_frame == 3 and not projectile_fired:
			_lanzar_proyectil()
			projectile_fired = true
	elif anim in ["attack", "special_attack"]:
		if anim == "special_attack" and current_frame in [2,3,4] and not special_attack_hit_done:
			_realizar_golpe()
			special_attack_hit_done = true
		elif anim == "attack" and current_frame == 2:
			_realizar_golpe()

	if current_frame == sprite.sprite_frames.get_frame_count(anim) - 1:
		await get_tree().create_timer(0.05).timeout
		is_attacking = false
		special_attack_hit_done = false

# -----------------------------
# DAÑO
# -----------------------------
func _realizar_golpe() -> void:
	pass

func _lanzar_proyectil() -> void:
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = spawn_point.global_position if spawn_point else global_position
		projectile.set_direction(-1 if sprite.flip_h else 1)
		print("Proyectil instanciado (daño: ", _damage, ")")
