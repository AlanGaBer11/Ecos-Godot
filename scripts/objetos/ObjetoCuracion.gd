# ObjetoCuracion.gd
class_name ObjetoCuracion
extends Area2D

@export var cantidad_curacion: int = 2 # Cantidad de vida que restaura este objeto
@export var tiempo_reaparicion: float = 5.0 # Tiempo para reaparecer (en segundos)
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@export var sonido_recoleccion: AudioStream # Sonido de recolección
var esta_disponible: bool = true # Estado del objeto

func _ready() -> void:	
	# Agregar animación de flotación
	agregar_animacion_flotante()

func _on_body_entered(body: Node2D) -> void:
	# Solo procesar si el objeto está disponible
	if not esta_disponible:
		return
	
	# Verificar si el cuerpo está en el grupo "personajes"
	if body.is_in_group("personajes"):
		if body.has_method("curar"):
			body.curar(cantidad_curacion)
			print(body.name, " curado por ", cantidad_curacion, " puntos")
			
			if sonido_recoleccion:
				reproducir_sonido()
			
			# Desactivar el objeto temporalmente
			desactivar_objeto()

func desactivar_objeto() -> void:
	esta_disponible = false
	
	# Aplicar efecto visual de recolección
	aplicar_efecto_recoleccion()
	
	# Esperar a que termine la animación (0.3 segundos)
	await get_tree().create_timer(0.3).timeout
	
	# Ocultar el objeto
	sprite.visible = false
	collision.disabled = true
	
	# Esperar el tiempo de reaparición
	await get_tree().create_timer(tiempo_reaparicion).timeout
	
	# Reactivar el objeto
	reactivar_objeto()

func reactivar_objeto() -> void:
	esta_disponible = true
	sprite.visible = true
	collision.disabled = false
	
	# Efecto de aparición (de pequeño a normal)
	sprite.scale = Vector2(1, 1)
	sprite.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(2, 2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	
	await tween.finished
	agregar_animacion_flotante()
	
	print("Objeto de curación reaparecido")

func agregar_animacion_flotante() -> void:
	# Matar cualquier tween anterior
	var tweens = get_tree().get_processed_tweens()
	for tween in tweens:
		if tween.is_valid():
			tween.kill()
	
	# Animación simple de flotación usando un Tween
	var tween = create_tween()
	tween.set_loops() # Repetir infinitamente
	tween.tween_property(self, "position:y", position.y - 10, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y + 10, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func aplicar_efecto_recoleccion() -> void:
	# Efecto visual de recolección (escalar y desvanecer)
	var tween = create_tween()
	tween.set_parallel(true) # Ejecutar ambas animaciones al mismo tiempo
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)

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
