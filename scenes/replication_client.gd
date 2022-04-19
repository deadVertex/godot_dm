extends Node

const NetworkReplication = preload("res://scenes/prefabs/network_replication.gd")

export var world_path: NodePath
export var player_scene: PackedScene

var _world: Node
var _entities: Array = []  # Change to dict with entity IDs?


func _ready():
	if world_path:
		_world = get_node(world_path)


func register_entity(entity: NetworkReplication):
	_entities.append(entity)


# FIXME: This is proof that _entities should be a dict!
func get_replicated_entity_by_name(name):
	for entity in _entities:
		if entity.get_name() == name:
			return entity


func apply_snapshot(snapshot):
	for entry in snapshot:
		if entry["type"] == "create":
			#print("Creating player entity")
			_create_player_entity(entry["initial_state"])

		elif entry["type"] == "update":
			#print("Update player entity")
			var entity = get_replicated_entity_by_name(entry["name"])
			# TODO: What do we do if entity is not found?
			entity.set_state(entry["state"])


func _create_player_entity(initial_state: Dictionary):
	var player = player_scene.instance()
	# Disable auto-registration with replication server
	var network_rep = player.get_node("NetworkReplication")
	network_rep.register_with_replication_server = false

	# Enable auto-registration with player command collector
	var cmd_generator = player.get_node("PlayerCommandGenerator")
	cmd_generator.register_with_collector = true

	# Disable player_cmd receiver on client
	var cmd_receiver = player.get_node("PlayerCommandReceiver")
	cmd_receiver.enabled = false

	# Add player to world and call _ready()
	_world.add_child(player)

	register_entity(network_rep)
	network_rep.set_initial_state(initial_state)
