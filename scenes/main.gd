extends Node

const NetworkTransport = preload("res://scenes/network_transport.gd")
const PlayerSpawner = preload("res://scenes/player_spawner.gd")
const ReplicationServer = preload("res://scenes/replication_server.gd")
const ReplicationClient = preload("res://scenes/replication_client.gd")
const PlayerCommandRouter = preload("res://scenes/player_command_router.gd")
const WeaponPickupSpawner = preload("res://scenes/weapon_pickup_spawner.gd")
const PlayerInputCollector = preload("res://scenes/player_input_collector.gd")
const Player = preload("res://scenes/prefabs/player.gd")
const BotSpawner = preload("res://scenes/bot_spawner.gd")

const VERSION_MAJOR: int = 0
const VERSION_MINOR: int = 1
const VERSION_PATCH: int = 0

const DEFAULT_PORT: int = 18000
const DEFAULT_MAX_CLIENTS: int = 8

# TODO: Up this number once we fix bots spawning inside each other
const BOT_COUNT = 1

export var map: PackedScene

var _is_server: bool = false

onready var _world: Spatial = $World
onready var _network_transport: NetworkTransport = $NetworkTransport
onready var _main_menu: Control = $UI/MainMenu
onready var _connect_to_server_window: Node = $UI/MainMenu/ConnectToServerWindow
onready var _player_spawner: PlayerSpawner = $PlayerSpawner
onready var _replication_server: ReplicationServer = $ReplicationServer
onready var _replication_client: ReplicationClient = $ReplicationClient
onready var _player_command_router: PlayerCommandRouter = $PlayerCommandRouter
onready var _weapon_pickup_spawner: WeaponPickupSpawner = $WeaponPickupSpawner
onready var _player_input_collector: PlayerInputCollector = $PlayerInputCollector
onready var _bot_spawner: BotSpawner = $BotSpawner

# TODO List
# - System for clients to request player spawns [x]
# - Controller node for player which receives commands from the client and
#   applies them to the player entity on the server [x]
# - Replicator node for player which receives state from the server and applies
#   it to the player entities on the clients [x]
# - Deployment automation [x]
# - Make sure we are using types everywhere! [x]
# - Unit tests! [x]
# - Buffer player commands?
# - Multiplayer shooting [x]
# - Multiple weapons (shotgun) [x]
# - Weapon pickups! [x]
# - Deleting network replicated entities [x]
# - Switch to ids for network entities [x]
# - Separate network replication nodes for client and server [ ]
# - Auto register entities to ReplicationClient [ ]
# - Move weapon logic into own node? [ ]
# - Make shotgun semi auto [/]
# - Test with multiple clients [x]
# - Fix Player view angles are getting messed up with multiple clients [x]
# - Able to see other players [x]
#	- Replicate player y rotation [x]
# - Able to kill other players [x]
# - Player respawning [x]
# - Bots? [ ]
#	- W+M1 player command generator [x]
#	- Navmesh driven player command generator [x]
#	- Aiming system [ ]
#	- Replace test brain [ ]
#	- System for spawning bots [x] (I want to specify a number of bots and have them spawn into the game)
#	- A way for bots to identify targets [ ]
#	- System for managing path finding requests (for rate limiting) [ ]
#	- Bot respawning [ ]
#	- Fix bots/players spawning inside each other [ ]
# - Weapon pickups respawn [ ]
# - Properly encapsulate player class so no external code is directly accessing
#   its child nodes [ ]
# - Upgrade to new godot 3.5 beta [ ]



func _ready() -> void:
	var args = _parse_cmdline_args(OS.get_cmdline_args())
	if args["listen"]:
		print("Starting server")
		_is_server = true
		var error = _network_transport.connect(
			"client_connected", self, "_on_client_connected"
		)
		if error != OK:
			print("network_transport.connect failed: %s" % error)

		_network_transport.start_server(DEFAULT_PORT, DEFAULT_MAX_CLIENTS)
		_load_map()
		_bot_spawner.player_spawner = _player_spawner
		_bot_spawner.spawn_bots(BOT_COUNT)
	else:
		var error = _network_transport.connect(
			"connection_accepted", self, "_on_connection_accepted"
		)
		if error != OK:
			print("network_transport.connect: %s" % error)

		error = _connect_to_server_window.connect(
			"connect_to_server", self, "_on_connect_to_server"
		)
		if error != OK:
			print("connect_to_server_window.connect: %s" % error)

		error = _replication_client.connect(
			"player_entity_created", self, "_on_player_entity_created"
		)
		assert(error == OK)
		error = _replication_client.connect(
			"player_entity_destroyed", self, "_on_player_entity_destroyed"
		)
		assert(error == OK)

		if args["connect"]:
			_on_connect_to_server("127.0.0.1", 18000)


func _on_connect_to_server(address: String, port: int) -> void:
	_main_menu.hide()
	print("Starting client")
	_network_transport.connect_to_server(address, port)


func _on_client_connected(id: int) -> void:
	print("Client connected: %d" % id)
	_replication_server.register_client(id)


func _on_connection_accepted(id: int) -> void:
	print("Connection accepted, id %d" % id)
	_load_map()  # TODO: Ask server which map to load
	# Request spawn
	var request = {"type": "spawn_request"}
	_network_transport.send_message_to_server(request)


func _on_player_entity_created(player: Player, is_locally_controlled: bool) -> void:
	print(
		"_on_player_entity_created: player: %s is_locally_controlled: %s" %
		[player, is_locally_controlled]
	)
	if is_locally_controlled:
		_player_input_collector.set_player_entity(player)


func _on_player_entity_destroyed(player: Player, is_locally_controlled: bool) -> void:
	print("_on_player_entity_destroyed: player %s is_locally_controlled: %s" %
		[player, is_locally_controlled]
	)
	if is_locally_controlled:
		# Request respawn
		var request = {"type": "spawn_request"}
		_network_transport.send_message_to_server(request)


func _parse_cmdline_args(args: PoolStringArray) -> Dictionary:
	var result: Dictionary = {"listen": false}
	for arg in args:
		if arg == "--listen":
			result["listen"] = true
		elif arg == "--connect":
			result["connect"] = true  # Only connect to local host for now

	return result


func _load_map() -> void:
	assert(map)
	var scene = map.instance()
	_world.add_child(scene)
	if _is_server:
		_weapon_pickup_spawner.spawn_weapon()


func _physics_process(_delta: float) -> void:
	if _is_server:
		_update_server()
	else:
		_update_client()


func _update_server() -> void:
	# Process incoming messages
	var message_queue = _network_transport.receive_messages()
	for entry in message_queue:
		var type = entry["message"]["type"]
		if type == "spawn_request":
			print("Player spawn requested!")
			var player = _player_spawner.spawn_player()

			# Connect new player entity to command router
			var client_id = entry["sender_id"]
			var cmd_receiver = player.get_node("PlayerCommandReceiver")
			assert(cmd_receiver)
			_player_command_router.register_receiver(cmd_receiver, client_id)

			# Set client id
			var network_rep = player.get_node("NetworkReplication")
			assert(network_rep)
			network_rep.controlling_client_id = client_id

		elif type == "player_cmd":
			#print("Player command received")
			_player_command_router.route_cmd(
				entry["message"]["data"], entry["sender_id"]
			)

	# Generate replication snapshots
	var snapshots = _replication_server.generate_snapshots_for_all_clients()

	# Send outgoing message for each snapshot
	for client_id in snapshots.keys():
		var message = {"type": "snapshot", "data": snapshots[client_id]}
		_network_transport.send_message_to_client(client_id, message)


func _update_client() -> void:
	# Process incoming messages
	var message_queue = _network_transport.receive_messages()
	for entry in message_queue:
		var type = entry["message"]["type"]
		var data = entry["message"]["data"]
		if type == "snapshot":
			#print("Snapshot received")
			_replication_client.apply_snapshot(data)

	# Collect player command
	var cmd = _player_input_collector.build_player_command()
	if cmd and not cmd.empty():
		# Send player command
		#print("Sending player command")
		var message = {"type": "player_cmd", "data": cmd}
		_network_transport.send_message_to_server(message)
