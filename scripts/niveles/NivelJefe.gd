extends Node2D

var player = null

func _ready() -> void:
	if CharacterManager != null:
		player = CharacterManager.currentPlayer.instantiate()
		add_child(player)
		player.global_position = $SpawnCharacter.global_position
