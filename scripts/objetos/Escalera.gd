extends Area2D

func _on_body_entered(body: Node) -> void:
	if body is Personaje:
		body.entrar_escalera()
		# print("Entró: ", body.name)
		

func _on_body_exited(body: Node) -> void:
	if body is Personaje:
		body.salir_escalera()
		# print("Salió: ", body.name)
