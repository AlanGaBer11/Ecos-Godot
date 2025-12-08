# game_manager.gd
extends Node

var vida_jugador: int = 10
var vida_maxima: int = 10

func guardar_vida(vida_actual: int) -> void:
	vida_jugador = vida_actual
	print("Vida guardada: ", vida_jugador)

func obtener_vida() -> int:
	return vida_jugador

func resetear_vida() -> void:
	vida_jugador = vida_maxima
	print("Vida reseteada a: ", vida_maxima)
