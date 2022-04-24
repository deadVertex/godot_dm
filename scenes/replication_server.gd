extends Node

const NetworkReplication = preload("res://scenes/prefabs/network_replication.gd")

export var world_path: NodePath

var _world: Node
var _entities: Dictionary = {}  # Change to dict with entity IDs?
var _events: Array = []  # Event queue to send to clients
var _clients: Dictionary = {}  # Key is client_id
var _next_id: int = 1


func _ready() -> void:
	if world_path:
		_world = get_node(world_path)


func register_entity(entity: NetworkReplication) -> void:
	# print("entity.connect network_event")
	# TODO: Make this optional
	var error = entity.connect(
		"network_event", self, "_on_entity_network_event"
	)
	assert(error == OK)

	# Allocate id
	var id = _next_id
	_next_id += 1

	entity.set_id(id)
	_entities[id] = entity

	error = entity.connect(
		"network_entity_deleted", self, "_on_network_entity_deleted")
	assert(error == OK)


func register_client(client_id: int) -> void:
	_clients[client_id] = []


# TODO: Include which entity this is from?
func _on_entity_network_event(event: Dictionary) -> void:
	# print("_on_entity_network_event")
	queue_event(event)


func queue_event(event: Dictionary) -> void:
	# print("queue_event: %s" % event)
	_events.append(event)


func add_entity_to_client(client_id: int, entity_id: int) -> void:
	_clients[client_id].append(entity_id)


func create_snapshot_for_client(client_id: int) -> Array:
	var snapshot = []
	for id in _entities.keys():
		var entity = _entities[id]
		if _clients[client_id].has(id):
			# Update
			var entry = {
				"type": "update",
				"id": id,
				"state": entity.get_state()
			}
			snapshot.append(entry)
		else:
			# Create
			var entry = {
				"type": "create",
				"id": id,
				"initial_state": entity.get_initial_state()
			}
			snapshot.append(entry)
			# print("create_snapshot_for_client: %s" % entry)
			# FIXME: We should not be modifying any data here!
			add_entity_to_client(client_id, id)

	for event in _events:
		var entry = {"type": "event", "data": event}
		# print("Network event sent: %s" % event)
		snapshot.append(entry)

	return snapshot


func generate_snapshots_for_all_clients() -> Dictionary:
	var snapshots = {}
	for client_id in _clients.keys():
		snapshots[client_id] = create_snapshot_for_client(client_id)

	# Clear event queue (not sure when the best time to do this is)
	_events.clear()

	return snapshots


func _on_network_entity_deleted(id: int) -> void:
	if not _entities.erase(id):
		print("Unable to find entity id %d" % id)


func get_entity_ids_to_delete_for_client(client_id: int) -> Array:
	var result = []
	var entity_ids = _clients[client_id]
	for id in entity_ids:
		if not _entities.has(id):
			result.append(id)
	
	return result
