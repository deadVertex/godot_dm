extends "res://addons/gut/test.gd"

# const WeaponPickup = preload("res://scenes/prefabs/weapon_pickup.gd")

func test_first():
	# Entities register themselves to the server if they need to be replicated to the client.
	var dummy_entity = autofree(Node.new())
	assert_eq(1,1)
