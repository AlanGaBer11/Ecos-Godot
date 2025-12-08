# Portal.gd
class_name Portal
extends Area2D

@export var next_level_path: String = "res://scenes/niveles/Nivel2.tscn"
@export var mensaje_sin_llave: String = "Necesitas una Llave"
@export var duracion_mensaje: float = 2.0
@export var sonido_portal: AudioStream # Opcional: sonido al entrar
@export var sonido_bloqueado: AudioStream # Opcional: sonido cuando no tiene llave

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D # Opcional: si tienes animación

var llave_en_escena: Llave = null
var puede_interactuar: bool = true
var label_mensaje: Label = null

func _ready() -> void:
	# Buscar la llave en la escena (debe estar en el grupo "llave")
	llave_en_escena = get_tree().get_first_node_in_group("llave")
	
	if not llave_en_escena:
		print("Advertencia: No se encontró ninguna llave en la escena")
	
	# Iniciar animación del portal si existe
	if sprite and sprite.sprite_frames:
		sprite.play("default") # O el nombre de tu animación

func _on_body_entered(body: Node2D) -> void:
	if not puede_interactuar:
		return
	
	if body is Personaje and body.es_jugador:
		# Verificar si tiene la llave
		if llave_en_escena and llave_en_escena.esta_con_jugador():
			# Tiene llave - entrar al portal
			entrar_portal()
		else:
			# No tiene llave - mostrar mensaje
			mostrar_mensaje_bloqueado()

func entrar_portal() -> void:
	puede_interactuar = false
	print("Portal activado - Cambiando a nivel: ", next_level_path)
	
	# Reproducir sonido de portal
	if sonido_portal:
		reproducir_sonido(sonido_portal)
	
	# Usar la llave (consumirla)
	if llave_en_escena:
		llave_en_escena.usar_llave()
	
	# Efecto de transición con ColorRect
	crear_fade_a_negro()

func crear_fade_a_negro() -> void:
	# Crear CanvasLayer para que esté por encima de todo
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)
	
	# Crear ColorRect negro
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0.0  # Empezar transparente
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(fade_rect)
	
	# Animar el fade
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await tween.finished
	
	# Cambiar de escena
	get_tree().change_scene_to_file(next_level_path)

func mostrar_mensaje_bloqueado() -> void:
	puede_interactuar = false
	print("Portal bloqueado - Se necesita llave")
	
	# Reproducir sonido de bloqueado (opcional)
	if sonido_bloqueado:
		reproducir_sonido(sonido_bloqueado)
	
	# Crear label temporal en el centro de la pantalla
	crear_mensaje_temporal()
	
	# Cooldown para evitar spam de mensajes
	await get_tree().create_timer(duracion_mensaje).timeout
	puede_interactuar = true

func crear_mensaje_temporal() -> void:
	# Crear CanvasLayer para el mensaje
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)
	
	# Crear el label
	label_mensaje = Label.new()
	label_mensaje.text = mensaje_sin_llave
	label_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_mensaje.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Estilo del texto
	label_mensaje.add_theme_font_size_override("font_size", 48)
	label_mensaje.add_theme_color_override("font_color", Color.WHITE)
	label_mensaje.add_theme_color_override("font_outline_color", Color.BLACK)
	label_mensaje.add_theme_constant_override("outline_size", 8)
	
	# Posicionar en el centro de la pantalla
	label_mensaje.set_anchors_preset(Control.PRESET_FULL_RECT)
	label_mensaje.position = Vector2.ZERO
	
	# Agregar al CanvasLayer
	canvas_layer.add_child(label_mensaje)
	
	# Animación de aparición
	label_mensaje.modulate.a = 0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(label_mensaje, "modulate:a", 1.0, 0.3)
	tween.tween_property(label_mensaje, "scale", Vector2(1.1, 1.1), 0.2).from(Vector2(0.5, 0.5))
	
	# Esperar y luego desvanecer
	await get_tree().create_timer(duracion_mensaje - 0.5).timeout
	
	var tween2 = create_tween()
	tween2.tween_property(label_mensaje, "modulate:a", 0.0, 0.5)
	await tween2.finished
	
	# Eliminar el CanvasLayer completo
	canvas_layer.queue_free()

func reproducir_sonido(sonido: AudioStream) -> void:
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = sonido
	audio_player.bus = "SFX"
	get_tree().root.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(func(): audio_player.queue_free())
