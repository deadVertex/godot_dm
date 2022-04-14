extends Node

export var map: PackedScene
onready var _world = $World

func _ready():
	_load_map()

func _load_map():
	assert(map)
	var scene = map.instance()
	_world.add_child(scene)
