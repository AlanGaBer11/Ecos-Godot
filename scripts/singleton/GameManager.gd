# game_manager.gd
extends Node

var vida_jugador: int = -1  # -1 significa "sin inicializar"
var personaje_actual: String = ""  # Nombre del personaje activo

func guardar_vida(vida_actual: int) -> void:
	vida_jugador = vida_actual
	print("Vida guardada: ", vida_jugador)

func obtener_vida() -> int:
	return vida_jugador

func resetear_vida() -> void:
	vida_jugador = -1
	personaje_actual = ""  #  También resetear el personaje
	print("Vida reseteada - se usará la vida máxima del personaje")

func inicializar_vida(vida_maxima: int, nombre_personaje: String) -> void:
	# Si cambió de personaje, resetear vida
	if personaje_actual != "" and personaje_actual != nombre_personaje:
		print("Cambio de personaje detectado: ", personaje_actual, " → ", nombre_personaje)
		vida_jugador = -1
	
	# Solo inicializar si no hay vida guardada
	if vida_jugador < 0:
		vida_jugador = vida_maxima
		personaje_actual = nombre_personaje
		print("Vida inicializada para ", nombre_personaje, ": ", vida_maxima)
