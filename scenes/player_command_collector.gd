extends Node

# FIXME: Cyclic dependencies
const PlayerCommandGenerator = preload("res://scenes/prefabs/player_command_generator.gd")

var _player_command_generator: PlayerCommandGenerator


func register(generator: PlayerCommandGenerator):
	_player_command_generator = generator


func build_player_command():
	if _player_command_generator:
		return _player_command_generator.build_player_command()
