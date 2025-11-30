# HUD.gd
class_name HUD
extends CanvasLayer

@onready var indicador_vida: IndicadorVida = $MarginContainer/VBoxContainer/IndicadorVida
var jugador: Personaje = null

func _ready() -> void:
	# Esperar un frame para asegurar que todo está cargado
	await get_tree().process_frame
	_conectar_jugador()

# Busca y conecta al jugador
func _conectar_jugador() -> void:
	# Buscar el jugador en la escena (puedes ajustar esto según tu estructura)
	jugador = get_tree().get_first_node_in_group("personajes")
	
	if not jugador:
		# Si no está en un grupo, buscar por tipo
		var personajes = get_tree().get_nodes_in_group("personajes")
		for personaje in personajes:
			if personaje is Personaje and personaje.es_jugador:
				jugador = personaje
				break
	
	if jugador:
		# Conectar la señal de cambio de vida
		jugador.vida_cambio.connect(_on_jugador_vida_cambio)
		
		# Inicializar el indicador con la vida del jugador
		if indicador_vida:
			indicador_vida.inicializar(jugador.get_max_salud())
			indicador_vida.actualizar_vida(jugador.get_salud_actual())
	else:
		push_error("No se encontró el jugador en la escena")

# Callback cuando cambia la vida del jugador
func _on_jugador_vida_cambio(vida_actual: int, _vida_maxima: int) -> void:
	if indicador_vida:
		indicador_vida.actualizar_vida(vida_actual)

# Método público para establecer el jugador manualmente si es necesario
func establecer_jugador(nuevo_jugador: Personaje) -> void:
	if jugador and jugador.vida_cambio.is_connected(_on_jugador_vida_cambio):
		jugador.vida_cambio.disconnect(_on_jugador_vida_cambio)
	
	jugador = nuevo_jugador
	if jugador:
		jugador.vida_cambio.connect(_on_jugador_vida_cambio)
		if indicador_vida:
			indicador_vida.inicializar(jugador.get_max_salud())
			indicador_vida.actualizar_vida(jugador.get_salud_actual())
