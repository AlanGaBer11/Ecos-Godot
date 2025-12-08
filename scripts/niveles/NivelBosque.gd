extends Node2D

var player = null
@onready var cam := $SpawnCharacter/Camera2D

func _ready() -> void:
	if CharacterManager != null:
		player = CharacterManager.currentPlayer.instantiate()
		add_child(player)
		player.global_position = $SpawnCharacter.global_position
		cam.enabled = true

func _process(delta: float) -> void:
	if player:
		cam.global_position = player.global_position
