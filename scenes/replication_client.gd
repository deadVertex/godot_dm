extends Node

const NetworkReplication = preload("res://scenes/prefabs/network_replication.gd")

export var world_path: NodePath
export var player_scene: PackedScene
#export var blood_splatter_fx_prefab: PackedScene
export var bullet_hole_prefab: PackedScene
export var bullet_hole_offset := 0.001

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

		elif entry["type"] == "event":
			# print("Network event received: %s" % entry["data"])
			_process_event(entry["data"])


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


func _process_event(event: Dictionary):
	if event["type"] == "bullet_impact":
		var position = event["position"]
		var normal = event["normal"]
		# print("Spawn bullet impact at %s with normal %s" % [position, normal])
		_spawn_bullet_hole(position, normal)


func _spawn_bullet_hole(position: Vector3, normal: Vector3):
	var bullet_hole = bullet_hole_prefab.instance()
	var up = Vector3.UP
	if normal.dot(up) >= 0.99999:
		up = Vector3.RIGHT

	bullet_hole.look_at_from_position(
		position + normal * bullet_hole_offset, position + normal, up
	)
	_world.add_child(bullet_hole)
