extends Node

const VERSION_MAJOR: int = 0
const VERSION_MINOR: int = 1
const VERSION_PATCH: int = 0

const DEFAULT_PORT: int = 18000
const DEFAULT_MAX_CLIENTS: int = 8

export var map: PackedScene
onready var _world = $World
onready var _network_transport = $NetworkTransport


func _ready():
	var args = _parse_cmdline_args(OS.get_cmdline_args())
	if args["listen"]:
		print("Starting server")
		_network_transport.connect(
			"client_connected", self, "_on_client_connected"
		)
		_network_transport.start_server(DEFAULT_PORT, DEFAULT_MAX_CLIENTS)
	else:
		print("Starting client")
		_network_transport.connect_to_server("127.0.0.1", DEFAULT_PORT)

	_load_map()


func _on_client_connected(id):
	print("Client connected: %d" % id)


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
