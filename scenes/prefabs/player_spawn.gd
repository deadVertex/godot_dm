extends Spatial

const Player = preload("res://scenes/prefabs/player.gd")

var _is_occupied := false

onready var _sprite = $Sprite3D


func _ready():
	_sprite.hide()  # Should only be visible in editor


func is_occupied() -> bool:
	return _is_occupied


func occupy() -> void:
	_is_occupied = true


func _on_area_body_entered(body: Node) -> void:
	print("player_spawn: _on_area_body_entered")
	if body is Player:
		_is_occupied = true


func _on_area_body_exited(body: Node) -> void:
	if body is Player:
		_is_occupied = false
