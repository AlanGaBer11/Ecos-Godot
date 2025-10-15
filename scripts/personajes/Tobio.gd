class_name Tobio
extends "res://scripts/personajes/Personaje.gd"

@export var projectile_scene: PackedScene
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_point: Node2D = $ProyectilSpawn

var last_direction: String = "right"
var can_shoot: bool = true
var is_attacking: bool = false
var projectile_fired: bool = false
var shoot_cooldown := 0.5
var current_attack_anim := ""

func _ready() -> void:
	_velocidad_base = 400.0
	_fuerza_salto_base = 450.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if not can_shoot:
		shoot_cooldown -= delta
		if shoot_cooldown <= 0.0:
			can_shoot = true

	# Detectar disparo
	if Input.is_action_just_pressed("fire") and can_shoot and not is_attacking:
		_disparar()

	# Evitar interrupciones
	if is_attacking:
		return

	# Animaciones normales
	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
	else:
		if velocity.x != 0:
			sprite.play("run")
			if velocity.x < 0:
				last_direction = "left"
			else:
				last_direction = "right"
			sprite.flip_h = (last_direction == "left")
		else:
			sprite.play("idle")
			sprite.flip_h = (last_direction == "left")





# ---------------------------------------------------
# DISPARO
# ---------------------------------------------------
func _disparar() -> void:
	is_attacking = true
	can_shoot = false
	shoot_cooldown = 0.5
	projectile_fired = false

	# Elegir animación según el estado
	if not is_on_floor() and sprite.sprite_frames.has_animation("jump_ranged_attack"):
		current_attack_anim = "jump_ranged_attack"
	else:
		current_attack_anim = "ranged_attack"

	# Reproducir la animación elegida
	if sprite.sprite_frames.has_animation(current_attack_anim):
		sprite.play(current_attack_anim)
	else:
		print("No existe la animación:", current_attack_anim)

# ---------------------------------------------------
# FRAME SYNC
# ---------------------------------------------------
func _on_animated_sprite_2d_frame_changed() -> void:
	if not is_attacking:
		return
	# Solo durante animaciones de ataque
	if sprite.animation == current_attack_anim:
		var current_frame = sprite.frame
		if current_frame == 3 and not projectile_fired:
			_lanzar_proyectil()
			projectile_fired = true
		# Cuando termina el último frame, volver al control normal
		if current_frame == sprite.sprite_frames.get_frame_count(current_attack_anim) - 1:
			# Esperar un poco antes de liberar el ataque
			await  get_tree().create_timer(0.05).timeout
			is_attacking = false

# ---------------------------------------------------
# LANZAR PROYECTIL
# ---------------------------------------------------
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
