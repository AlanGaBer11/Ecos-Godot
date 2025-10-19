extends Label

func _process(delta: float) -> void:
	show_fps()
	

func show_fps():
	var fps = Engine.get_frames_per_second()
	
	text = "FPS: " + str(fps)
