extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 1.5
var direction: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = lifetime
	timer.start()
	connect("area_entered", Callable(self, "_on_area_entered"))
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

func set_direction(dir: int) -> void:
	direction = dir
	sprite.flip_h = direction < 0

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		if area.has_method("recibir_danio"):
			area.recibir_danio(10)
		# animación de destrucción opcional
		sprite.play("projectile_destroy")
		await sprite.animation_finished
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
