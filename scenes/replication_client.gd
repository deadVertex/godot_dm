extends Node

const NetworkReplication = preload("res://scenes/prefabs/network_replication.gd")
const EntityFactory = preload("res://scenes/entity_factory.gd")

const Player = preload("res://scenes/prefabs/player.gd")
const WeaponPickup = preload("res://scenes/prefabs/weapon_pickup.gd")

export(NodePath) var world_path
export(PackedScene) var player_scene
#export var blood_splatter_fx_prefab: PackedScene
export(PackedScene) var bullet_hole_prefab
export(float) var bullet_hole_offset = 0.001
export(PackedScene) var weapon_pickup_scene

var _world: Node
var _entities: Array = []  # Change to dict with entity IDs?
var _entity_factory: EntityFactory


func _ready() -> void:
	if world_path:
		_world = get_node(world_path)

	_entity_factory = EntityFactory.new()
	_entity_factory.world = _world
	_entity_factory.player_scene = player_scene
	_entity_factory.weapon_pickup_scene = weapon_pickup_scene


func register_entity(entity: NetworkReplication) -> void:
	_entities.append(entity)


# FIXME: This is proof that _entities should be a dict!
func get_replicated_entity_by_id(id: int) -> NetworkReplication:
	var result: NetworkReplication = null
	for entity in _entities:
		if entity.get_id() == id:
			result = entity
			break

	return result


func apply_snapshot(snapshot: Array) -> void:
	#print("apply_snapshot: snapshot.size() = %d" % snapshot.size())
	for entry in snapshot:
		if entry["type"] == "create":
			_create_entity(entry["id"], entry["initial_state"])

		elif entry["type"] == "update":
			#print("Update player entity")
			var entity = get_replicated_entity_by_id(entry["id"])
			if entity:
				entity.set_state(entry["state"])
			else:
				# TODO: What do we do if entity is not found?
				print("apply_snapshot: entity id %s not found" % entry["id"])

		elif entry["type"] == "delete":
			_delete_entity(entry["id"])

		elif entry["type"] == "event":
			# print("Network event received: %s" % entry["data"])
			_process_event(entry["data"])


func _create_entity(id: int, initial_state: Dictionary) -> void:
	print("_create_entity: id: %s initial_state: %s" % [id, initial_state])
	var entity = null
	match initial_state["type"]:
		NetworkReplication.EntityType.PLAYER:
			entity = _create_player_entity(initial_state)
		NetworkReplication.EntityType.OTHER:
			entity = _create_weapon_pickup(initial_state)
		_:
			print("Unknown type: %s" % initial_state)

	entity.set_id(id)
	register_entity(entity)
	entity.set_initial_state(initial_state)


func _create_weapon_pickup(initial_state: Dictionary) -> NetworkReplication:
	print("_create_weapon_pickup: %s" % initial_state)
	var pickup = _entity_factory.create_weapon_pickup(initial_state)

	var network_rep = pickup.get_node("WeaponPickupNetworkReplication")
	return network_rep


func _create_player_entity(initial_state: Dictionary) -> NetworkReplication:
	print("_create_player_entity: %s" % initial_state)
	var player = _entity_factory.create_player(initial_state)

	var network_rep = player.get_node("NetworkReplication")
	return network_rep


func _process_event(event: Dictionary) -> void:
	if event["type"] == "bullet_impact":
		var position = event["position"]
		var normal = event["normal"]
		# print("Spawn bullet impact at %s with normal %s" % [position, normal])
		_spawn_bullet_hole(position, normal)


func _spawn_bullet_hole(position: Vector3, normal: Vector3) -> void:
	var bullet_hole = bullet_hole_prefab.instance()
	var up = Vector3.UP
	if normal.dot(up) >= 0.99999:
		up = Vector3.RIGHT

	bullet_hole.look_at_from_position(
		position + normal * bullet_hole_offset, position + normal, up
	)
	_world.add_child(bullet_hole)


func _delete_entity(id: int) -> void:
	print("_delete_entity: %d" % id)
	var entity = get_replicated_entity_by_id(id)
	if entity:
		_entities.erase(entity)
		entity.delete_entity()
	else:
		print("Unable to find entity for id %d" % id)
