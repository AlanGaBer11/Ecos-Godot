# SelectCharacter.gd
extends Control

@export var Personajes: Array[CharacterData]
@onready var sprite = $MainLayout/SpriteConainer/Sprite2D

# Referencias a los labels de características
@onready var name_label = $MainLayout/NameLabel
@onready var description_label = $MainLayout/MarginContainer/CharacterStats/DescriptionLabel

# Referencias a las barras de progreso
@onready var health_bar = $MainLayout/MarginContainer/CharacterStats/StatsContainer/HealthContainer/HealthBar
@onready var damage_bar = $MainLayout/MarginContainer/CharacterStats/StatsContainer/DamageContainer/DamageBar
@onready var speed_bar = $MainLayout/MarginContainer/CharacterStats/StatsContainer/SpeedContainer/SpeedBar
@onready var jump_bar = $MainLayout/MarginContainer/CharacterStats/StatsContainer/JumpContainer/JumpBar

var cont: int = 0

func _ready() -> void:
	update_character_display()

func update_character_display() -> void:
	var current_character = Personajes[cont]
	sprite.texture = current_character.image
	
	# Actualizar las características
	name_label.text = current_character.id
	description_label.text = current_character.description
	
	# Actualizar barras de progreso con valores directos
	health_bar.value = current_character.health
	damage_bar.value = current_character.damage
	speed_bar.value = current_character.speed
	jump_bar.value = current_character.jump_power
	
	animate_bars()

func animate_bars() -> void:
	var current_character = Personajes[cont]
	
	# Crear tweens para animar las barras
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Resetear barras a 0
	health_bar.value = 0
	damage_bar.value = 0
	speed_bar.value = speed_bar.min_value
	jump_bar.value = jump_bar.min_value
	
	# Animar con delays escalonados
	tween.tween_property(health_bar, "value", current_character.health, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(damage_bar, "value", current_character.damage, 0.5).set_ease(Tween.EASE_OUT).set_delay(0.1)
	tween.tween_property(speed_bar, "value", current_character.speed, 0.5).set_ease(Tween.EASE_OUT).set_delay(0.2)
	tween.tween_property(jump_bar, "value", current_character.jump_power, 0.5).set_ease(Tween.EASE_OUT).set_delay(0.3)

func previous() -> void:
	if cont > 0:
		cont -= 1
		update_character_display()

func next() -> void:
	if cont < Personajes.size() - 1:
		cont += 1
		update_character_display()

func select() -> void:
	CharacterManager.currentPlayer = Personajes[cont].scene
	
func _on_previous_pressed() -> void:
	previous()
	
func _on_next_pressed() -> void:
	next()
	
func _on_select_pressed() -> void:
	select()
	get_tree().change_scene_to_file("res://scenes/niveles/Nivel_Bosque.tscn")
