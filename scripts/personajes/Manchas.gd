# Manchas.gd
class_name Manchas
extends "res://scripts/personajes/Personaje.gd"

@onready var attack_area: Area2D = $AttackArea

var last_direction := "right"
var is_attacking := false
var current_attack_anim := ""
var special_attack_hit_done := false
var waiting_for_double := false
var double_attack_time := 0.5
var last_attack_time := 0.0

func _ready() -> void:
	es_jugador = true
	_velocidad_base = 380.0
	_fuerza_salto_base = 380.0
	_max_salud = 15
	_damage = 2
	_saltos_disponibles = 1
	super._ready()
	
	attack_area.monitoring = false
	
	print("Manchas iniciado - es_jugador: ", es_jugador)

func _on_attack_area_body_entered(body: Node) -> void:
	if is_attacking and body != self:
		aplicar_dano(body)

func _physics_process(delta: float) -> void:
	if not _esta_vivo:
		return
	
	super._physics_process(delta)
	
	# -----------------------------
	# DETECCIÓN DE ATAQUE SIMPLE / DOBLE
	# -----------------------------
	if Input.is_action_just_pressed("ui_attack"):
		var now = Time.get_ticks_msec() / 1000.0
		if now - last_attack_time < double_attack_time:
			# Si presionó rápido, ejecutar ataque doble
			waiting_for_double = false
			last_attack_time = 0.0
			_ataque_doble()
		else:
			# Si es el primer toque, ejecutar ataque básico
			last_attack_time = now
			_atacar()
	
	# Ataque especial solo si no está atacando
	if Input.is_action_just_pressed("ui_special_attack") and not is_attacking and not _is_taking_damage:
		_ataque_especial()
	
	# -----------------------------
	# BLOQUEAR MOVIMIENTO DURANTE ATAQUE
	# -----------------------------
	if is_attacking or _is_taking_damage:
		return
	
	# -----------------------------
	# ANIMACIONES
	# -----------------------------
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
	current_attack_anim = "jump_attack" if not is_on_floor() else "attack"
	sprite.play(current_attack_anim)

func _ataque_doble() -> void:
	# Permitir interrumpir cualquier ataque actual
	is_attacking = true
	current_attack_anim = "attack_2_hits"
	sprite.play(current_attack_anim)

func _ataque_especial() -> void:
	if is_attacking: return
	is_attacking = true
	special_attack_hit_done = false
	current_attack_anim = "special_attack"
	sprite.play(current_attack_anim)

func _realizar_golpe() -> void:
	attack_area.monitoring = true
	await get_tree().create_timer(0.1).timeout
	attack_area.monitoring = false

# -----------------------------
# FRAME SYNC
# -----------------------------
func _on_animated_sprite_2d_frame_changed() -> void:
	var anim = sprite.animation
	var current_frame = sprite.frame
	
	# Ejecutar golpes en frames específicos según la animación
	if anim in ["attack", "jump_attack", "attack_2_hits", "special_attack"]:
		if anim == "special_attack" and current_frame in [2,3,4] and not special_attack_hit_done:
			_realizar_golpe()
			special_attack_hit_done = true
		elif anim == "attack" and current_frame == 2:
			_realizar_golpe()
		elif anim == "jump_attack" and current_frame == 1:
			_realizar_golpe()
		elif anim == "attack_2_hits" and current_frame == 2:
			_realizar_golpe()
	
	# Terminar ataque cuando llega al último frame
	if anim in ["attack", "jump_attack", "attack_2_hits", "special_attack"] and current_frame == sprite.sprite_frames.get_frame_count(anim) - 1:
		await get_tree().create_timer(0.05).timeout
		is_attacking = false
		special_attack_hit_done = false
