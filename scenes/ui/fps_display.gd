extends Control

onready var _label = $Label


func _process(delta):
	var fps = 1.0 / delta
	_label.text = "FPS: %d (%.02f ms)" % [fps, delta]
