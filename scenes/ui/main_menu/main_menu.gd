extends Control

onready var _connect_to_server_window = $ConnectToServerWindow


func _on_play_button_pressed():
	_connect_to_server_window.popup()


func _on_quit_button_pressed():
	get_tree().quit(0)
