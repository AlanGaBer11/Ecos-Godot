extends Control

# Referencias a los nodos
@onready var death_text = $CenterContainer/VBoxContainer/DeathText
@onready var buttons_container = $CenterContainer/VBoxContainer/ButtonsContainer
@onready var button_reintentar = $CenterContainer/VBoxContainer/ButtonsContainer/ReintentarButton
@onready var button_menu = $CenterContainer/VBoxContainer/ButtonsContainer/MenuButton
@onready var button_salir = $CenterContainer/VBoxContainer/ButtonsContainer/ExitButton
@onready var death_sound = $"../Sounds/DeathSound"
@onready var select_sound = $"../Sounds/SelectSound"
@onready var confirm_sound = $"../Sounds/ConfirmSound"

var buttons = []
var current_button = 0

func _ready():
		# Asegurar que ocupe toda la pantalla
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Reproducir sonido de muerte al aparecer
	if death_sound and death_sound.stream:
		death_sound.play()
	
	# Ocultar todo al inicio
	modulate.a = 0
	death_text.modulate.a = 0
	buttons_container.modulate.a = 0
	
	# Configurar botones
	buttons = [button_reintentar, button_menu, button_salir]
	
	# Conectar señales de los botones
	button_reintentar.pressed.connect(_on_reintentar_pressed)
	button_menu.pressed.connect(_on_menu_pressed)
	button_salir.pressed.connect(_on_salir_pressed)
	
	# Conectar señales de hover
	for i in range(buttons.size()):
		buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))
	
	# Iniciar animación
	_start_animation()
	
	# Seleccionar primer botón
	_update_button_selection()

func _start_animation():
	# Fade in de fondo
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Aparecer texto "HAS MUERTO"
	await get_tree().create_timer(0.5).timeout
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_OUT)
	tween2.set_trans(Tween.TRANS_BACK)
	tween2.tween_property(death_text, "modulate:a", 1.0, 0.8)
	tween2.parallel().tween_property(death_text, "scale", Vector2.ONE, 0.8).from(Vector2(0.5, 0.5))
	
	# Aparecer botones
	await get_tree().create_timer(1.0).timeout
	var tween3 = create_tween()
	tween3.tween_property(buttons_container, "modulate:a", 1.0, 0.5)

func _input(event):
	if buttons_container.modulate.a < 1.0:
		return
	
	if event.is_action_pressed("ui_page_down"):
		current_button = (current_button + 1) % buttons.size()
		_update_button_selection()
		_play_select_sound()
		
	elif event.is_action_pressed("ui_page_up"):
		current_button = (current_button - 1 + buttons.size()) % buttons.size()
		_update_button_selection()
		_play_select_sound()
		
	elif event.is_action_pressed("ui_accept"):
		buttons[current_button].emit_signal("pressed")
		_play_confirm_sound()

func _update_button_selection():
	for i in range(buttons.size()):
		if i == current_button:
			buttons[i].add_theme_color_override("font_color", Color.BLACK)
			buttons[i].add_theme_color_override("font_hover_color", Color.BLACK)
			
			# Agregar estilo de selección
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.86, 0.15, 0.15) # Rojo
			style.corner_radius_top_left = 0
			style.corner_radius_top_right = 0
			style.corner_radius_bottom_left = 0
			style.corner_radius_bottom_right = 0
			style.set_border_width_all(0)
			style.shadow_color = Color(0.86, 0.15, 0.15, 0.6)
			style.shadow_size = 10
			buttons[i].add_theme_stylebox_override("normal", style)
			buttons[i].add_theme_stylebox_override("hover", style)
			
			# Animación de escala
			var tween = create_tween()
			tween.tween_property(buttons[i], "scale", Vector2(1.05, 1.05), 0.2)
		else:
			buttons[i].remove_theme_color_override("font_color")
			buttons[i].remove_theme_color_override("font_hover_color")
			
			# Estilo normal
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0.5)
			style.border_color = Color(0.4, 0.1, 0.1)
			style.set_border_width_all(2)
			buttons[i].add_theme_stylebox_override("normal", style)
			
			var style_hover = StyleBoxFlat.new()
			style_hover.bg_color = Color(0.1, 0.1, 0.1, 0.7)
			style_hover.border_color = Color(0.86, 0.15, 0.15)
			style_hover.set_border_width_all(2)
			buttons[i].add_theme_stylebox_override("hover", style_hover)
			
			var tween = create_tween()
			tween.tween_property(buttons[i], "scale", Vector2.ONE, 0.2)

func _on_button_hovered(index):
	current_button = index
	_update_button_selection()
	_play_select_sound()

func _on_reintentar_pressed():
	_fade_out_and_reload()

func _on_menu_pressed():
	_fade_out_and_go_to_menu()

func _on_salir_pressed():
	get_tree().quit()

func _fade_out_and_reload():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	get_tree().reload_current_scene()

func _fade_out_and_go_to_menu():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _play_select_sound():
	if select_sound and select_sound.stream:
		select_sound.play()

func _play_confirm_sound():
	if confirm_sound and confirm_sound.stream:
		confirm_sound.play()
