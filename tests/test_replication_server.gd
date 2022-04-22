extends "res://addons/gut/test.gd"

const ReplicationServer = preload("res://scenes/replication_server.gd")
const ReplicationClient = preload("res://scenes/replication_client.gd")
const NetworkReplication = preload("res://scenes/prefabs/network_replication.gd")
const EntityFactory = preload("res://scenes/entity_factory.gd")

const WeaponPickupScene = preload("res://scenes/prefabs/weapon_pickup.tscn")

# TODO: Auto register entities to ReplicationClient

func test_replication_server():
	var replication_server = autofree(ReplicationServer.new())

	var entity = double(NetworkReplication).new()
	replication_server.register_entity(entity)

	var client_id = 1
	replication_server.register_client(client_id)

	assert_false(replication_server._entities.empty())
	assert_false(replication_server._clients.empty())

	var snapshot = replication_server.create_snapshot_for_client(client_id)
	assert_eq(snapshot.size(), 1)
	assert_eq(snapshot[0]["type"], "create")

	var next_snapshot = replication_server.create_snapshot_for_client(client_id)
	assert_eq(next_snapshot.size(), 1)
	assert_eq(next_snapshot[0]["type"], "update")


func test_replication_client():
	var entity_factory = double(EntityFactory).new()
	var weapon_pickup = double(WeaponPickupScene).instance()
	stub(entity_factory, "create_weapon_pickup").to_return(weapon_pickup)

	# Given a replication client
	var replication_client = autofree(ReplicationClient.new())
	replication_client._entity_factory = entity_factory
	assert_true(replication_client._entities.empty())


	# When we receive a snapshot
	var create_snapshot = []
	create_snapshot.append({
		"type": "create",
		"initial_state": { 
			"type": NetworkReplication.EntityType.OTHER
		}
	})
	replication_client.apply_snapshot(create_snapshot)

	# Then we register the new entity
	assert_eq(replication_client._entities.size(), 1)


# TODO: Split into two tests
func test_replication_client_update() -> void:
	var entity_factory = double(EntityFactory).new()

	# Given a replication client
	var replication_client = autofree(ReplicationClient.new())
	replication_client._entity_factory = entity_factory

	# When we register an entity
	var entity = autofree(double(NetworkReplication).new())
	entity.set_name("asdf")
	replication_client.register_entity(entity)

	# Then we can retrieve it by name
	assert_eq(replication_client.get_replicated_entity_by_name("asdf"),
		entity)

	# When we receive an update snapshot
	var update_snapshot = []
	update_snapshot.append({
		"type": "update",
		"name": "asdf",
		"state": {}
	})
	replication_client.apply_snapshot(update_snapshot)

	# Then we set the state on the entity
	assert_called(entity, "set_state")


func test_replication_integration() -> void:
	var server = autofree(ReplicationServer.new())
	var client = autofree(ReplicationClient.new())

	var entity_factory = EntityFactory.new()
	entity_factory.world = add_child_autofree(Spatial.new())
	entity_factory.weapon_pickup_scene = WeaponPickupScene
	client._entity_factory = entity_factory

	# Create server-side entity
	var server_entity = add_child_autofree(WeaponPickupScene.instance())
	server_entity.set_name("bob")
	var network_rep = server_entity.get_node("WeaponPickupNetworkReplication")
	assert_not_null(network_rep)
	server.register_entity(network_rep)
	var client_id = 1
	server.register_client(client_id)

	var snapshots = server.generate_snapshots_for_all_clients()
	assert_has(snapshots, client_id)

	var snapshot = snapshots[client_id]

	client.apply_snapshot(snapshot)
	# Check that we created a weapon pickup at Vector3(1, 2, 3)