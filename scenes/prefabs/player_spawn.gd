extends Spatial

onready var _sprite = $Sprite3D


func _ready():
	_sprite.hide()  # Should only be visible in editor
