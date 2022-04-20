extends Node

const NetworkReplication = preload("res://scenes/prefabs/network_replication.gd")

export var world_path: NodePath

var _world: Node
var _entities: Array = []  # Change to dict with entity IDs?
var _events: Array = []  # Event queue to send to clients
var _clients: Dictionary = {}  # Key is client_id


func _ready():
	if world_path:
		_world = get_node(world_path)


func register_entity(entity: NetworkReplication):
	# print("entity.connect network_event")
	var error = entity.connect(
		"network_event", self, "_on_entity_network_event"
	)
	assert(error == OK)
	_entities.append(entity)


func register_client(client_id: int):
	_clients[client_id] = []


# TODO: Include which entity this is from?
func _on_entity_network_event(event: Dictionary):
	# print("_on_entity_network_event")
	queue_event(event)


func queue_event(event: Dictionary):
	# print("queue_event: %s" % event)
	_events.append(event)


func create_snapshot_for_client(client_id: int):
	var snapshot = []
	for entity in _entities:
		# TODO: Don't use entity name
		if _clients[client_id].has(entity.get_name()):
			# Update
			var entry = {
				"type": "update",
				"name": entity.get_name(),
				"state": entity.get_state()
			}
			snapshot.append(entry)
		else:
			# Create
			var entry = {
				"type": "create",
				"name": entity.get_name(),
				"initial_state": entity.get_initial_state()
			}
			snapshot.append(entry)
			# FIXME: We should not be modifying any data here!
			_clients[client_id].append(entity.get_name())

	for event in _events:
		var entry = {"type": "event", "data": event}
		# print("Network event sent: %s" % event)
		snapshot.append(entry)

	return snapshot


func generate_snapshots_for_all_clients():
	var snapshots = {}
	for client_id in _clients.keys():
		snapshots[client_id] = create_snapshot_for_client(client_id)

	# Clear event queue (not sure when the best time to do this is)
	_events.clear()

	return snapshots
