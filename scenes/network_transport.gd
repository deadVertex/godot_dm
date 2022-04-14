# This class is responsible for all network transport so that if we decide to
# change our transport layer (i.e. use Steam networking or roll our own with
# raw sockets) its a very well contained change that shouldn't affect anything
# else.
class_name NetworkTransport
extends Node

signal connection_accepted(client_id)
signal client_connected(client_id)

var _message_queue = []


func start_server(port, max_clients):
	get_tree().connect("network_peer_connected", self, "on_client_connected")

	var net = NetworkedMultiplayerENet.new()
	net.create_server(port, max_clients)
	get_tree().set_network_peer(net)
	#Logger.info("Hosting server on port %d" % port)
	print("Hosting server on port %d" % port)


func connect_to_server(address, port):
	get_tree().connect("connected_to_server", self, "on_connection_accepted")

	#Logger.info("Connecting to server %s on port %d" % [address, port])
	print("Connecting to server %s on port %d" % [address, port])
	var net = NetworkedMultiplayerENet.new()
	net.create_client(address, port)
	get_tree().set_network_peer(net)


func on_connection_accepted():
	var client_id = get_tree().get_network_unique_id()
	emit_signal("connection_accepted", client_id)


func on_client_connected(client_id):
	emit_signal("client_connected", client_id)


func send_message_to_server(message):
	#Logger.debug('SEND_TO_SERVER: %s' % message)
	rpc_unreliable_id(1, "_receive_message", message)


func send_message_to_client(client_id, message):
	#Logger.debug('SEND_TO_CLIENT: %d %s' % [client_id, message])
	rpc_unreliable_id(client_id, "_receive_message", message)


remote func _receive_message(message):
	var sender_id = get_tree().get_rpc_sender_id()
	#Logger.debug('RECEIVE: %d %s' % [sender_id, message])
	var entry = {"message": message, "sender_id": sender_id}
	_message_queue.append(entry)


# FIXME: This is not a very obvious behavior, could easily introduce issues
func receive_messages():
	var result = _message_queue.duplicate()
	_message_queue.clear()
	return result
