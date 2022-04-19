extends Node

const VERSION_MAJOR: int = 0
const VERSION_MINOR: int = 1
const VERSION_PATCH: int = 0

const DEFAULT_PORT: int = 18000
const DEFAULT_MAX_CLIENTS: int = 8

export var map: PackedScene

var _is_server: bool = false

onready var _world = $World
onready var _network_transport = $NetworkTransport
onready var _main_menu = $UI/MainMenu
onready var _connect_to_server_window = $UI/MainMenu/ConnectToServerWindow
onready var _player_spawner = $PlayerSpawner
onready var _replication_server = $ReplicationServer
onready var _replication_client = $ReplicationClient
onready var _player_command_collector = $PlayerCommandCollector
onready var _player_command_router = $PlayerCommandRouter

# TODO List
# - System for clients to request player spawns [x]
# - Controller node for player which receives commands from the client and
#   applies them to the player entity on the server
# - Replicator node for player which receives state from the server and applies
#   it to the player entities on the clients [x]


func _ready():
	var args = _parse_cmdline_args(OS.get_cmdline_args())
	if args["listen"]:
		print("Starting server")
		_is_server = true
		_network_transport.connect(
			"client_connected", self, "_on_client_connected"
		)
		_network_transport.start_server(DEFAULT_PORT, DEFAULT_MAX_CLIENTS)
		_load_map()
	else:
		_network_transport.connect(
			"connection_accepted", self, "_on_connection_accepted"
		)
		_connect_to_server_window.connect(
			"connect_to_server", self, "_on_connect_to_server"
		)


func _on_connect_to_server(address: String, port: int):
	_main_menu.hide()
	print("Starting client")
	_network_transport.connect_to_server(address, port)


func _on_client_connected(id):
	print("Client connected: %d" % id)
	_replication_server.register_client(id)


func _on_connection_accepted(id):
	print("Connection accepted, id %d" % id)
	_load_map()  # TODO: Ask server which map to load
	# Request spawn
	var request = {"type": "spawn_request"}
	_network_transport.send_message_to_server(request)


func _parse_cmdline_args(args: PoolStringArray):
	var result: Dictionary = {"listen": false}
	for arg in args:
		if arg == "--listen":
			result["listen"] = true

	return result


func _load_map():
	assert(map)
	var scene = map.instance()
	_world.add_child(scene)


func _physics_process(delta: float):
	if _is_server:
		_update_server()
	else:
		_update_client()


func _update_server():
	# Process incoming messages
	var message_queue = _network_transport.receive_messages()
	for entry in message_queue:
		var type = entry["message"]["type"]
		if type == "spawn_request":
			print("Player spawn requested!")
			_player_spawner.spawn_player(entry["sender_id"])
		elif type == "player_cmd":
			print("Player command received")
			_player_command_router.route_cmd(
				entry["message"]["data"], entry["sender_id"]
			)

	# Generate replication snapshots
	var snapshots = _replication_server.generate_snapshots_for_all_clients()

	# Send outgoing message for each snapshot
	for client_id in snapshots.keys():
		var message = {"type": "snapshot", "data": snapshots[client_id]}
		_network_transport.send_message_to_client(client_id, message)


func _update_client():
	# Process incoming messages
	var message_queue = _network_transport.receive_messages()
	for entry in message_queue:
		var type = entry["message"]["type"]
		var data = entry["message"]["data"]
		if type == "snapshot":
			print("Snapshot received")
			_replication_client.apply_snapshot(data)

	# Collect player command
	var cmd = _player_command_collector.build_player_command()
	if cmd:
		# Send player command
		print("Sending player command")
		var message = {"type": "player_cmd", "data": cmd}
		_network_transport.send_message_to_server(message)
