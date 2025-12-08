# llave_manager.gd
extends Node

var llave_correcta: Llave = null
var todas_las_llaves: Array[Llave] = []

func registrar_llave(llave: Llave) -> void:
	todas_las_llaves.append(llave)
	print("Llave registrada: ", llave.name, " - Total: ", todas_las_llaves.size())

func inicializar_llaves() -> void:
	if todas_las_llaves.is_empty():
		print("No hay llaves registradas")
		return
	
	# Elegir una llave aleatoria como la correcta
	var index_aleatorio = randi() % todas_las_llaves.size()
	llave_correcta = todas_las_llaves[index_aleatorio]
	llave_correcta.marcar_como_correcta()
	
	print("Llave correcta seleccionada: ", llave_correcta.name)

func obtener_llave_correcta() -> Llave:
	return llave_correcta

func resetear() -> void:
	llave_correcta = null
	todas_las_llaves.clear()
	print("LlaveManager reseteado")
