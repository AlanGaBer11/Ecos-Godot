# Llave.gd
class_name Llave
extends Area2D

@export var sonido_recoleccion: AudioStream # Sonido de recolección
@export var offset_seguimiento: Vector2 = Vector2(-40, -20) # Posición relativa al jugador
@export var velocidad_seguimiento: float = 10.0 # Qué tan rápido sigue al jugador
@export var distancia_activacion: float = 50.0 # Distancia para empezar a flotar

var esta_recogida: bool = false
var jugador: Node2D = null
var posicion_flotante: Vector2 = Vector2.ZERO
var tiempo_flotacion: float = 0.0

func _process(delta: float) -> void:
	if esta_recogida and jugador:
		# Efecto de flotación (movimiento ondulatorio)
		tiempo_flotacion += delta * 3.0
		var ondulacion = sin(tiempo_flotacion) * 5.0
		
		# Posición objetivo (detrás y arriba del jugador)
		posicion_flotante = jugador.global_position + offset_seguimiento + Vector2(0, ondulacion)
		
		# Interpolar suavemente hacia la posición objetivo
		global_position = global_position.lerp(posicion_flotante, velocidad_seguimiento * delta)
		
		# Pequeña rotación para efecto visual
		rotation = sin(tiempo_flotacion * 0.5) * 0.1

func _on_body_entered(body: Node2D) -> void:
	if body is Personaje and body.es_jugador and not esta_recogida:
		recoger_llave(body)

func recoger_llave(player: Node2D) -> void:
	esta_recogida = true
	jugador = player
	
	# Reproducir sonido
	if sonido_recoleccion:
		reproducir_sonido()
	
	# Desactivar colisión para que no se vuelva a recoger
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Efecto visual de recolección
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.8, 0.2)
	
	# Cambiar a una capa de renderizado superior (opcional)
	z_index = 100
	
	print("¡Llave recogida! Ahora sigue al jugador")

func reproducir_sonido() -> void:
	# Crear un AudioStreamPlayer temporal para el sonido
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = sonido_recoleccion
	audio_player.bus = "SFX" 
	
	# Agregar a la escena principal 
	get_tree().root.add_child(audio_player)
	audio_player.play()
	
	# Eliminar el reproductor cuando termine
	audio_player.finished.connect(func(): audio_player.queue_free())

# Método público para verificar si la llave está recogida
func esta_con_jugador() -> bool:
	return esta_recogida

# Método para dejar de seguir (por si necesitas usarla en una puerta)
func usar_llave() -> void:
	if esta_recogida:
		# Animación de uso
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		await tween.finished
		queue_free()
