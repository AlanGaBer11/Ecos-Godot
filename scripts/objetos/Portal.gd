# Portal.gd
class_name Portal
extends Area2D

@export var next_level_path: String = "res://scenes/niveles/Nivel2.tscn"
@export var mensaje_sin_llave: String = "Necesitas la Llave Correcta" 
@export var duracion_mensaje: float = 2.0
@export var sonido_portal: AudioStream
@export var sonido_bloqueado: AudioStream

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var puede_interactuar: bool = true
var label_mensaje: Label = null

func _ready() -> void:
	# Iniciar animación del portal
	if sprite and sprite.sprite_frames:
		sprite.play("default")

func _on_body_entered(body: Node2D) -> void:
	if not puede_interactuar:
		return
	
	if body is Personaje and body.es_jugador:
		# Verificar si tiene la llave CORRECTA
		var llave_correcta = LlaveManager.obtener_llave_correcta()
		
		if llave_correcta and llave_correcta.esta_con_jugador():
			# ✅ Tiene la llave correcta
			entrar_portal()
		else:
			# ❌ No tiene la llave correcta
			mostrar_mensaje_bloqueado()

func entrar_portal() -> void:
	puede_interactuar = false
	print("Portal activado - Cambiando a nivel: ", next_level_path)
	
	# Reproducir sonido de portal
	if sonido_portal:
		reproducir_sonido(sonido_portal)
	
	# Usar la llave
	var llave_correcta = LlaveManager.obtener_llave_correcta()
	if llave_correcta:
		llave_correcta.usar_llave()
	
	# Resetear el manager para el próximo nivel
	LlaveManager.resetear()
	
	# Efecto de transición
	crear_fade_a_negro()

func crear_fade_a_negro() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(fade_rect)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await tween.finished
	
	get_tree().change_scene_to_file(next_level_path)

func mostrar_mensaje_bloqueado() -> void:
	puede_interactuar = false
	print("Portal bloqueado - Se necesita la llave correcta")
	
	if sonido_bloqueado:
		reproducir_sonido(sonido_bloqueado)
	
	crear_mensaje_temporal()
	
	await get_tree().create_timer(duracion_mensaje).timeout
	puede_interactuar = true

func crear_mensaje_temporal() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)
	
	label_mensaje = Label.new()
	label_mensaje.text = mensaje_sin_llave
	label_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_mensaje.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	label_mensaje.add_theme_font_size_override("font_size", 48)
	label_mensaje.add_theme_color_override("font_color", Color.WHITE)
	label_mensaje.add_theme_color_override("font_outline_color", Color.BLACK)
	label_mensaje.add_theme_constant_override("outline_size", 8)
	
	# Configurar pivot en el centro
	label_mensaje.set_anchors_preset(Control.PRESET_FULL_RECT)
	label_mensaje.position = Vector2.ZERO
	label_mensaje.pivot_offset = label_mensaje.size / 2  # Centro como pivot
	
	canvas_layer.add_child(label_mensaje)
	
	# Animación sin escala (solo fade)
	label_mensaje.modulate.a = 0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label_mensaje, "modulate:a", 1.0, 0.3)
	
	# Esperar y desvanecer
	await get_tree().create_timer(duracion_mensaje - 0.5).timeout
	
	var tween2 = create_tween()
	tween2.tween_property(label_mensaje, "modulate:a", 0.0, 0.5)
	await tween2.finished
	
	canvas_layer.queue_free()

func reproducir_sonido(sonido: AudioStream) -> void:
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = sonido
	audio_player.bus = "SFX"
	get_tree().root.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(func(): audio_player.queue_free())
