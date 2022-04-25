var world: Node
var player_scene: PackedScene
var weapon_pickup_scene: PackedScene


func create_player(initial_state: Dictionary):
	print("_create_player_entity: %s" % initial_state)

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
	world.add_child(player)

	return player


func create_weapon_pickup(initial_state: Dictionary):
	print("_create_weapon_pickup: %s" % initial_state)
	var pickup = weapon_pickup_scene.instance()
	pickup.is_server = false

	# Disable auto-registration with replication server
	var network_rep = pickup.get_node("WeaponPickupNetworkReplication")
	network_rep.register_with_replication_server = false

	# Add player to world and call _ready()
	world.add_child(pickup)

	return pickup
