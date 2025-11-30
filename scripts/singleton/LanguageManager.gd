extends Node

var current_language: String = "es"

func _ready():
	load_saved_language()

func load_saved_language():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		current_language = config.get_value("general", "language", "es")
	change_language(current_language)

func change_language(lang_code: String):
	current_language = lang_code
	TranslationServer.set_locale(lang_code)
	save_language()

func save_language():
	var config = ConfigFile.new()
	config.set_value("general", "language", current_language)
	config.save("user://settings.cfg")
