extends "res://addons/gut/test.gd"

const ReplicationServer = preload("res://scenes/replication_server.gd")
const ReplicationClient = preload("res://scenes/replication_client.gd")
const NetworkReplication = preload("res://scenes/prefabs/network_replication.gd")
const EntityFactory = preload("res://scenes/entity_factory.gd")

const WeaponPickupScene = preload("res://scenes/prefabs/weapon_pickup.tscn")

# TODO: Auto register entities to ReplicationClient
# Separate network replication nodes for client and server


func test_network_replication_emits_signal_on_delete():
	var network_rep = NetworkReplication.new()
	network_rep.entity_type = NetworkReplication.EntityType.OTHER
	add_child(network_rep)
	watch_signals(network_rep)
	remove_child(network_rep)
	assert_signal_emitted(network_rep, "network_entity_deleted")
	network_rep.free()


func test_network_replication_deletes_root_on_client():
	var entity = WeaponPickupScene.instance()
	var network_rep = entity.get_node("WeaponPickupNetworkReplication")
	assert_not_null(network_rep)
	network_rep.register_with_replication_server = false # i.e. this is on the client
	add_child(entity)

	network_rep.delete_entity()
	assert_freed(entity, "entity")


func test_replication_server():
	var replication_server = autofree(ReplicationServer.new())

	print("register_entity")
	var entity = double(NetworkReplication).new()
	stub(entity, "get_id").to_return(1)
	replication_server.register_entity(entity)
	print("register_client")

	var client_id = 1
	replication_server.register_client(client_id)

	assert_false(replication_server._entities.empty())
	assert_false(replication_server._clients.empty())

	print("create")
	var snapshot = replication_server.create_snapshot_for_client(client_id)
	assert_eq(snapshot.size(), 1)
	assert_eq(snapshot[0]["type"], "create")

	print("update")
	var next_snapshot = replication_server.create_snapshot_for_client(client_id)
	assert_eq(next_snapshot.size(), 1)
	assert_eq(next_snapshot[0]["type"], "update")


func test_replication_server_allocates_id():
	var replication_server = autofree(ReplicationServer.new())
	assert_eq(replication_server._next_id, 1)

	var entity = double(NetworkReplication).new()
	replication_server.register_entity(entity)

	assert_called(entity, "set_id", [1])
	assert_eq(replication_server._next_id, 2)


func test_replication_server_sends_id():
	var replication_server = autofree(ReplicationServer.new())

	var entity = double(NetworkReplication).new()
	stub(entity, "get_id").to_return(1)
	replication_server.register_entity(entity)

	var client_id = 1
	replication_server.register_client(client_id)

	var snapshot = replication_server.create_snapshot_for_client(client_id)
	assert_eq(snapshot[0]["type"], "create")
	assert_eq(snapshot[0]["id"], 1)


func test_replication_server_tracks_id():
	var replication_server = autofree(ReplicationServer.new())

	var entity = double(NetworkReplication).new()
	stub(entity, "get_id").to_return(1)
	replication_server.register_entity(entity)

	var client_id = 1
	replication_server.register_client(client_id)

	var create_snapshot = replication_server.create_snapshot_for_client(
		client_id
	)
	assert_eq(create_snapshot[0]["type"], "create")
	assert_eq(create_snapshot[0]["id"], 1)

	var update_snapshot = replication_server.create_snapshot_for_client(
		client_id
	)
	assert_eq(update_snapshot[0]["type"], "update")
	assert_eq(update_snapshot[0]["id"], 1)


func test_replication_server_listens_for_entity_deletion():
	var replication_server = autofree(ReplicationServer.new())

	var entity = double(NetworkReplication).new()
	stub(entity, "get_id").to_return(1)
	replication_server.register_entity(entity)
	entity.emit_signal("network_entity_deleted", 1)

	assert_eq(replication_server._entities.size(), 0)

	var client_id = 1
	replication_server.register_client(client_id)
	replication_server.add_entity_to_client(client_id, 1)

	var ids_to_delete = replication_server.get_entity_ids_to_delete_for_client(client_id)
	assert_eq(ids_to_delete[0], 1)


func test_replication_server_generate_deletion_snapshot():
	var replication_server = autofree(ReplicationServer.new())

	var entity = double(NetworkReplication).new()
	stub(entity, "get_id").to_return(1)
	replication_server.register_entity(entity)
	entity.emit_signal("network_entity_deleted", 1)

	var client_id = 1
	replication_server.register_client(client_id)
	replication_server.add_entity_to_client(client_id, 1)

	var snapshot = replication_server.create_snapshot_for_client(
		client_id
	)
	assert_eq(snapshot[0]["type"], "delete")
	assert_eq(snapshot[0]["id"], 1)


func test_replication_server_only_generates_deletion_event_once():
	var replication_server = autofree(ReplicationServer.new())

	var entity = double(NetworkReplication).new()
	stub(entity, "get_id").to_return(1)
	replication_server.register_entity(entity)
	entity.emit_signal("network_entity_deleted", 1)

	var client_id = 1
	replication_server.register_client(client_id)
	replication_server.add_entity_to_client(client_id, 1)

	var snapshot = replication_server.create_snapshot_for_client(
		client_id
	)
	assert_eq(snapshot.size(), 1)
	assert_eq(snapshot[0]["type"], "delete")

	var new_snapshot = replication_server.create_snapshot_for_client(
		client_id
	)
	assert_eq(new_snapshot.size(), 0)


func test_replication_client():
	var entity_factory = double(EntityFactory).new()
	var weapon_pickup = double(WeaponPickupScene).instance()
	stub(entity_factory, "create_weapon_pickup").to_return(weapon_pickup)

	var network_rep = autofree(double(NetworkReplication).new())
	replace_node(weapon_pickup, "WeaponPickupNetworkReplication", network_rep)

	# Given a replication client
	var replication_client = autofree(ReplicationClient.new())
	replication_client._entity_factory = entity_factory
	assert_true(replication_client._entities.empty())

	# When we receive a snapshot
	var create_snapshot = []
	create_snapshot.append(
		{
			"type": "create",
			"id": 1,
			"initial_state": {"type": NetworkReplication.EntityType.OTHER}
		}
	)
	replication_client.apply_snapshot(create_snapshot)

	# Then we register the new entity
	assert_eq(replication_client._entities.size(), 1)


func test_replication_client_sets_id_on_create():
	var entity_factory = double(EntityFactory).new()
	var weapon_pickup = autofree(double(WeaponPickupScene).instance())
	stub(entity_factory, "create_weapon_pickup").to_return(weapon_pickup)

	var network_rep = autofree(double(NetworkReplication).new())
	replace_node(weapon_pickup, "WeaponPickupNetworkReplication", network_rep)

	# Given a replication client
	var replication_client = autofree(ReplicationClient.new())
	replication_client._entity_factory = entity_factory

	# When we receive a snapshot with an ID
	var create_snapshot = []
	create_snapshot.append(
		{
			"type": "create",
			"id": 1,
			"initial_state": {"type": NetworkReplication.EntityType.OTHER}
		}
	)
	replication_client.apply_snapshot(create_snapshot)

	# Then we the new NetworkReplication node to that ID
	assert_called(network_rep, "set_id", [1])


# TODO: Split into two tests
func test_replication_client_update() -> void:
	var entity_factory = double(EntityFactory).new()

	# Given a replication client
	var replication_client = autofree(ReplicationClient.new())
	replication_client._entity_factory = entity_factory

	# When we register an entity
	var entity = autofree(double(NetworkReplication).new())
	stub(entity, "get_id").to_return(1)
	replication_client.register_entity(entity)

	# Then we can retrieve it by name
	assert_eq(replication_client.get_replicated_entity_by_id(1), entity)

	# When we receive an update snapshot
	var update_snapshot = []
	update_snapshot.append({"type": "update", "id": 1, "state": {}})
	replication_client.apply_snapshot(update_snapshot)

	# Then we set the state on the entity
	assert_called(entity, "set_state")


func test_replication_client_deletes_entity() -> void:
	var entity_factory = double(EntityFactory).new()

	# Given a replication client with an entity
	var replication_client = autofree(ReplicationClient.new())
	replication_client._entity_factory = entity_factory

	var network_rep = double(NetworkReplication).new()
	stub(network_rep, "get_id").to_return(1)
	replication_client.register_entity(network_rep)

	# When we receive an delete snapshot
	var snapshot = []
	snapshot.append({"type": "delete", "id": 1})
	replication_client.apply_snapshot(snapshot)

	# Then we free the entity
	assert_called(network_rep, "delete_entity")

	# And remove it from the entities list
	assert_eq(replication_client._entities.size(), 0)


func test_replication_integration() -> void:
	var server = autofree(ReplicationServer.new())
	var client = autofree(ReplicationClient.new())

	var entity_factory = EntityFactory.new()
	entity_factory.world = add_child_autofree(Spatial.new())
	entity_factory.weapon_pickup_scene = WeaponPickupScene
	client._entity_factory = entity_factory

	# Create server-side entity
	var server_entity = add_child_autofree(WeaponPickupScene.instance())
	server_entity.global_transform.origin = Vector3(1, 2, 3)
	var network_rep = server_entity.get_node("WeaponPickupNetworkReplication")
	assert_not_null(network_rep)
	server.register_entity(network_rep)
	var client_id = 1
	server.register_client(client_id)

	# Generate a snapshot on the server and process on client
	var snapshots = server.generate_snapshots_for_all_clients()
	assert_has(snapshots, client_id)

	var snapshot = snapshots[client_id]

	client.apply_snapshot(snapshot)

	# Check that we created a weapon pickup entity with the
	# expected initial position
	var client_entity = entity_factory.world.get_node("WeaponPickup")
	assert_not_null(client_entity)
	assert_eq(client_entity.global_transform.origin, Vector3(1, 2, 3))

	# Delete server-side entity
	remove_child(server_entity)

	# Generate new snapshot on the server and process on client
	snapshots = server.generate_snapshots_for_all_clients()
	assert_has(snapshots, client_id)
	snapshot = snapshots[client_id]

	client.apply_snapshot(snapshot)

	# Check that the entity is removed on the client
	assert_freed(client_entity, "client_entity")
