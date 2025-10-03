class_name Prueba
extends "res://scripts/personajes/Personaje.gd"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var last_direction: String = "side"

func _ready() -> void:
	_velocidad_base = 400.0
	_fuerza_salto_base = 450.0

func _physics_process(delta: float) -> void:
	# Lógica base de movimiento y salto
	super._physics_process(delta)

	# Animaciones según estado
	if not is_on_floor():
		# Si está en el aire
		if velocity.y < 0:
			sprite.play("jump") # Animación de salto
		else:
			sprite.play("fall") # Animación de caída
		sprite.flip_h = velocity.x < 0
	elif velocity.x != 0:
		# En el suelo y moviéndose
		sprite.play("run")
		sprite.flip_h = velocity.x < 0
		last_direction = "side"
	else:
		# En el suelo y quieto
		sprite.play("idle")
		sprite.flip_h = last_direction == "side" and sprite.flip_h
