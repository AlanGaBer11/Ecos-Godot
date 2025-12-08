class_name Killzone
extends Area2D

@onready var timer = $Timer

@export var dano_caida: int = 2  # 👈 Daño que resta al caer
@export var usar_efecto_slow_motion: bool = true
@export var velocidad_slow_motion: float = 0.4
@export var tiempo_respawn: float = 0.5

var jugador_en_zona: Personaje = null

func _on_body_entered(body: Node2D) -> void:
	# Verificar que sea el jugador
	if body is Personaje and body.es_jugador:
		jugador_en_zona = body
		print("¡Te caíste!")
		
		# Aplicar daño al jugador
		body.recibir_danio(dano_caida, global_position)
		
		# Verificar si murió después del daño
		if body.get_salud_actual() <= 0:
			# Si murió, dejar que el sistema de muerte lo maneje
			if usar_efecto_slow_motion:
				Engine.time_scale = velocidad_slow_motion
				await get_tree().create_timer(tiempo_respawn).timeout
				Engine.time_scale = 1.0
			return
		
		# Si sobrevivió, hacer respawn
		if usar_efecto_slow_motion:
			Engine.time_scale = velocidad_slow_motion
		
		if timer:
			timer.wait_time = tiempo_respawn
			timer.start()

func _on_timer_timeout() -> void:
	# Restaurar velocidad normal
	Engine.time_scale = 1.0
	
	# Resetear llaves 
	LlaveManager.resetear()
	
	# Solo recargar si el jugador sigue vivo
	if jugador_en_zona and jugador_en_zona.get_salud_actual() > 0:
		get_tree().reload_current_scene()
	
	jugador_en_zona = null
