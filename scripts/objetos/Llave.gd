# Llave.gd
class_name Llave
extends Area2D

@export var sonido_recoleccion: AudioStream
@export var sonido_incorrecta: AudioStream  # Sonido cuando es incorrecta
@export var offset_seguimiento: Vector2 = Vector2(-40, -20)
@export var velocidad_seguimiento: float = 10.0
@export var distancia_activacion: float = 50.0

var esta_recogida: bool = false
var es_correcta: bool = false 
var jugador: Node2D = null
var posicion_flotante: Vector2 = Vector2.ZERO
var tiempo_flotacion: float = 0.0

func _ready() -> void:
	# Registrar esta llave en el manager
	LlaveManager.registrar_llave(self)
	
	# Si es la primera llave en registrarse y hay 5, inicializar
	call_deferred("verificar_inicializacion")

func verificar_inicializacion() -> void:
	# Esperar un frame para que todas las llaves se registren
	await get_tree().process_frame
	
	# Si somos la quinta llave, inicializar el sistema
	if LlaveManager.todas_las_llaves.size() == 5 and LlaveManager.llave_correcta == null:
		LlaveManager.inicializar_llaves()

func marcar_como_correcta() -> void:
	es_correcta = true
	# Efecto visual opcional: brillo dorado
	# modulate = Color(1.0, 1.0, 0.7)  # Tinte amarillo/dorado sutil

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
	
	if es_correcta:
		# LLAVE CORRECTA
		jugador = player
		print("¡Llave correcta recogida!")
		
		if sonido_recoleccion:
			reproducir_sonido(sonido_recoleccion)
		
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
		tween.tween_property(self, "modulate", Color(1.0, 0.84, 0.0, 0.9), 0.2)
		
		z_index = 100
		
		mostrar_mensaje("¡Llave del portal encontrada!", Color(1.0, 0.84, 0.0))
		
	else:
		# LLAVE INCORRECTA
		print("Llave incorrecta recogida")
		
		if sonido_incorrecta:
			reproducir_sonido(sonido_incorrecta)
		elif sonido_recoleccion:
			reproducir_sonido(sonido_recoleccion)
		
		# Crear el mensaje de forma independiente (sin await)
		crear_mensaje_independiente("Esta llave no sirve...", Color(0.7, 0.7, 0.7))
		
		# Animar desaparición de la llave
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.5)
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		await tween.finished
		
		# Eliminar la llave
		queue_free()

func crear_mensaje_independiente(texto: String, color: Color) -> void:
	# Crear CanvasLayer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().root.add_child(canvas_layer)  # 👈 Agregar a root, no a current_scene
	
	# Crear el label
	var label = Label.new()
	label.text = texto
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Estilo
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.position = Vector2.ZERO
	
	canvas_layer.add_child(label)
	
	# Animación de aparición
	label.modulate.a = 0
	var tween_in = canvas_layer.create_tween()
	tween_in.tween_property(label, "modulate:a", 1.0, 0.3)
	
	# Programar desvanecimiento y eliminación
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		if is_instance_valid(canvas_layer):
			var tween_out = canvas_layer.create_tween()
			tween_out.tween_property(label, "modulate:a", 0.0, 0.5)
			tween_out.finished.connect(func():
				if is_instance_valid(canvas_layer):
					canvas_layer.queue_free()
			)
	)

func mostrar_mensaje(texto: String, color: Color) -> void:
	# Crear CanvasLayer para el mensaje
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)
	
	# Crear el label
	var label = Label.new()
	label.text = texto
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Estilo del texto
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	
	# Posicionar en el centro COMPLETO de la pantalla
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.position = Vector2.ZERO
	
	canvas_layer.add_child(label)
	
	# Animación
	label.modulate.a = 0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	
	# Desvanecer
	await get_tree().create_timer(1.5).timeout
	var tween2 = create_tween()
	tween2.tween_property(label, "modulate:a", 0.0, 0.5)
	await tween2.finished
	
	canvas_layer.queue_free()

func reproducir_sonido(sonido: AudioStream) -> void:
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = sonido
	audio_player.bus = "SFX" 
	get_tree().root.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(func(): audio_player.queue_free())

func esta_con_jugador() -> bool:
	return esta_recogida and es_correcta  # Solo es válida si es correcta

func usar_llave() -> void:
	if esta_recogida and es_correcta:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		await tween.finished
		queue_free()
		
