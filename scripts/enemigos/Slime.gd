# Slime.gd
class_name Slime
extends Area2D

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D

@export var dano_contacto: int = 1  # Daño que hace el slime al tocar
@export var cooldown_dano: float = 1.0  # Tiempo entre daños

const velocidad = 60
var direccion = 1
var puede_hacer_dano: bool = true

func _process(delta) -> void:
	if ray_cast_right.is_colliding():
		direccion = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direccion = 1
		animated_sprite.flip_h = false
		
	position.x += direccion * velocidad * delta

# Quitar vida si el jugador lo toca
func _on_body_entered(body: Node2D) -> void:
	# Verificar que sea el personaje/jugador y que pueda hacer daño
	if body is Personaje and body.es_jugador and puede_hacer_dano:
		print("Aplicando daño a ", body.name)
		# Aplicar daño al jugador
		body.recibir_danio(dano_contacto, global_position)
		
		# Iniciar cooldown para evitar daño continuo
		puede_hacer_dano = false
		await get_tree().create_timer(cooldown_dano).timeout
		puede_hacer_dano = true
