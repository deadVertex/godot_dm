extends Node

const NetworkReplication = preload("res://scenes/prefabs/network_replication.gd")

export var world_path: NodePath
export var player_scene: PackedScene

var _world: Node
var _entities: Array = []  # Change to dict with entity IDs?


func _ready():
	if world_path:
		_world = get_node(world_path)


# TODO: What type is entity?
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
			print("Creating player entity")
			var player = player_scene.instance()
			var network_rep = player.get_node("NetworkReplication")
			network_rep.register_with_replication_server = false
			_world.add_child(player)
			register_entity(network_rep)
			network_rep.set_initial_state(entry["initial_state"])

		elif entry["type"] == "update":
			print("Update player entity")
			var entity = get_replicated_entity_by_name(entry["name"])
			# TODO: What do we do if entity is not found?
			entity.set_state(entry["state"])
