class_name CharacterData
extends Resource

@export var id: String
@export var image: Texture2D
@export var scene: PackedScene

# Características del personaje
@export_range(0, 20) var health: int
@export_range(0, 5) var damage: int
@export_range(300, 600) var speed: float
@export_range(300, 600) var jump_power: float
@export_multiline var description: String
