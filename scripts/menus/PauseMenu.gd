extends Control 

@onready var continue_btn = $VBoxContainer/ButtonContainer/ContinueBtn 
@onready var options_btn = $VBoxContainer/ButtonContainer/OptionsBtn 
@onready var exit_btn = $VBoxContainer/ButtonContainer/ExitBtn 
@onready var confirm_dialog = $ConfirmationDialog 


func _ready() -> void: 
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Si regresamos de opciones con el juego pausado, mostrar el menú
	if SceneManager.is_game_paused:
		visible = true
		get_tree().paused = true
		print("Menú de pausa restaurado después de opciones")
	else:
		visible = false
	
	continue_btn.pressed.connect(_on_continue_pressed) 
	options_btn.pressed.connect(_on_options_pressed) 
	exit_btn.pressed.connect(_on_exit_pressed) 
	confirm_dialog.confirmed.connect(_on_confirm_exit) 
	confirm_dialog.canceled.connect(_on_cancel_exit) 


func _input(event): 
	if event.is_action_pressed("pause"): 
		_toggle_pause() 


# --- Funciones de botones --- 

func _on_continue_pressed() -> void: 
	get_tree().paused = false
	SceneManager.is_game_paused = false  # Resetear el estado
	visible = false 
	print("Juego reanudado") 

func _on_options_pressed() -> void: 
	get_tree().paused = false 
	SceneManager.is_game_paused = true  # Marcar que venimos del juego pausado
	SceneManager.go_to_scene("res://scenes/menus/OptionsMenu.tscn")
	print("Escena de opciones abierta desde pausa") 

func _on_exit_pressed() -> void: 
	confirm_dialog.title = "¿Guardar y salir?" 
	confirm_dialog.dialog_text = "¿Deseas volver al menú principal?" 
	confirm_dialog.popup_centered() 

func _on_confirm_exit() -> void: 
	get_tree().paused = false 
	SceneManager.is_game_paused = false
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn") 
	print("Saliendo al menú principal") 

func _on_cancel_exit() -> void: 
	print("Canceló salida") 


# --- Función auxiliar --- 
func _toggle_pause() -> void: 
	if get_tree().paused: 
		get_tree().paused = false
		SceneManager.is_game_paused = false
		visible = false 
		print("Juego reanudado") 
	else: 
		get_tree().paused = true
		SceneManager.is_game_paused = true
		visible = true 
		print("Juego pausado")
