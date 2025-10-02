# Tobio hereda de Personaje (Herencia).

class_name Tobio
extends "res://scripts/personajes/Personaje.gd"

func _ready():
	# Personalizar atributos: Tobio es más rápido y salta más.
	_velocidad_base = 400.0
	_fuerza_salto_base = 450.0
