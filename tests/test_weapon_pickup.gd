extends "res://addons/gut/test.gd"

const WeaponPickup = preload("res://scenes/prefabs/weapon_pickup.tscn")
const WeaponPickupSpawnPoint = preload("res://scenes/prefabs/weapon_pickup_spawn_point.tscn")
const WeaponPickupSpawner = preload("res://scenes/weapon_pickup_spawner.gd")
const Player = preload("res://scenes/prefabs/player.tscn")
# Just for enums...
const ViewModel = preload("res://scenes/prefabs/view_model.gd")


func test_overlap_area():
	# Given a weapon pickup
	var weapon_pickup = add_child_autofree(WeaponPickup.instance())
	weapon_pickup.weapon = ViewModel.Weapon.SHOTGUN

	# When a player overlaps with the pickup
	var player = add_child_autofree(double(Player).instance())
	var area = weapon_pickup.get_node("Area")
	# TODO: Replace with moving player into area?
	area.emit_signal("body_entered", player)

	# Then the player receives the weapon from the pickup
	assert_called(player, "give_weapon", [ViewModel.Weapon.SHOTGUN])


# TODO: Implement factory to fix resource leaks
#func test_weapon_spawn_system():
	## Given a weapon spawner
	#var spawner = WeaponPickupSpawner.new()
	#var world = add_child_autofree(double(Spatial).new())
	#spawner.world_path = world.get_path()

	#spawner.weapon_pickup_scene = WeaponPickup
	#add_child_autofree(spawner)

	## And a spawn point
	#var spawn_point = add_child_autofree(WeaponPickupSpawnPoint.instance())
	#spawn_point.global_transform.origin = Vector3(1, 2, 3)

	## When we request to spawn a weapon
	#spawner.spawn_weapon()

	## Then a weapon pickup is added to the world
	#var expected = spawn_point.get_node("SpawnPoint").global_transform.origin
	#print(expected)
	##assert_eq(pickup.global_transform.origin, expected, Vector3(0.0001, 0.0001, 0.0001))
