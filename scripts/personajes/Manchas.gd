class_name Manchas
extends "res://scripts/personajes/Personaje.gd"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea  # <- Area2D para golpes

var last_direction: String = "right"
var is_attacking: bool = false
var current_attack_anim := ""
var special_attack_hit_done := false

func _ready() -> void:
	_velocidad_base = 300.0       # Más lento
	_fuerza_salto_base = 400.0
	_max_salud = 15               # Más salud
	_damage = 3                    # Ataque fuerte
	_saltos_disponibles = 1        # Solo un salto
	super._ready()
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))

func _on_attack_area_body_entered(body: Node) -> void:
	if is_attacking:
		aplicar_dano(body)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if Input.is_action_just_pressed("ui_attack"):
		_atacar()
	if Input.is_action_just_pressed("ui_special_attack") and not is_attacking:
		_ataque_especial()
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
	current_attack_anim = "jump_attack" if not is_on_floor() and sprite.sprite_frames.has_animation("jump_attack") else "attack"
	if sprite.sprite_frames.has_animation(current_attack_anim):
		sprite.play(current_attack_anim)

func _ataque_especial() -> void:
	if is_attacking:
		return
	is_attacking = true
	special_attack_hit_done = false
	current_attack_anim = "special_attack"
	if sprite.sprite_frames.has_animation(current_attack_anim):
		sprite.play(current_attack_anim)

# -----------------------------
# ANIMACIÓN SYNC
# -----------------------------
func _on_animated_sprite_2d_frame_changed() -> void:
	if not is_attacking:
		return
	var current_frame = sprite.frame
	var anim = sprite.animation
	if anim == current_attack_anim:
		if anim in ["attack", "jump_attack", "special_attack"]:
			if anim == "special_attack" and current_frame in [2,3,4] and not special_attack_hit_done:
				_aplicar_dano()
				special_attack_hit_done = true
			elif anim != "special_attack" and current_frame == 2:
				_aplicar_dano()
		if current_frame == sprite.sprite_frames.get_frame_count(anim) - 1:
			await get_tree().create_timer(0.05).timeout
			is_attacking = false
			special_attack_hit_done = false

# -----------------------------
# APLICAR DAÑO
# -----------------------------
func _aplicar_dano() -> void:
	# Ya no usamos get_overlapping_bodies(), el Area2D se encarga
	pass
