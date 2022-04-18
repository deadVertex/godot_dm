extends Node

export var world_path: NodePath

var _world: Node
var _entities: Array = []  # Change to dict with entity IDs?
var _clients: Dictionary = {}  # Key is client_id


func _ready():
	if world_path:
		_world = get_node(world_path)


# TODO: What type is entity?
func register_entity(entity):
	_entities.append(entity)


func register_client(client_id: int):
	_clients[client_id] = []


func create_snapshot_for_client(client_id: int):
	var snapshot = []
	for entity in _entities:
		# TODO: What type is this entity?????
		if _clients[client_id].has(entity.get_name()):
			# Update
			var entry = {"type": "update", "name": entity.get_name()}
			snapshot.append(entry)
		else:
			# Create
			# TODO: What entity type?
			var entry = {"type": "create", "name": entity.get_name()}
			snapshot.append(entry)
			# FIXME: We should not be modifying any data here!
			_clients[client_id].append(entity.get_name())

	return snapshot


func generate_snapshots_for_all_clients():
	var snapshots = {}
	for client_id in _clients.keys():
		snapshots[client_id] = create_snapshot_for_client(client_id)

	return snapshots
