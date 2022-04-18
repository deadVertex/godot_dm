extends Node

export var world_path: NodePath
export var player_scene: PackedScene

var _world: Node
var _entities: Array = []  # Change to dict with entity IDs?


func _ready():
	if world_path:
		_world = get_node(world_path)


# TODO: What type is entity?
func register_entity(entity):
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
			# TODO: Set player state?
			_world.add_child(player)
			register_entity(player)

		elif entry["type"] == "update":
			print("Update player entity")
			var entity = get_replicated_entity_by_name(entry["name"])
			# TODO: What do we do if entity is not found?
