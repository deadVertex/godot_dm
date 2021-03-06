extends Node

const PlayerCommandReceiver = preload("res://scenes/prefabs/player_command_receiver.gd")

var _receivers: Dictionary = {}


func register_receiver(receiver: PlayerCommandReceiver, client_id: int):
	#print("register_receiver: client_id: %d" % client_id)
	_receivers[client_id] = receiver


func route_cmd(player_cmd: Dictionary, client_id: int):
	#print("route_cmd: client_id: %d" % client_id)
	#print("%s receive_player_cmd" % _receivers[client_id])
	var receiver = _receivers.get(client_id)
	if is_instance_valid(receiver):
		receiver.receive_player_cmd(player_cmd)
