extends "res://addons/gut/test.gd"

const WeaponPickup = preload("res://scenes/prefabs/weapon_pickup.tscn")
const Player = preload("res://scenes/prefabs/player.tscn")
# Just for enums...
const ViewModel = preload("res://scenes/prefabs/view_model.gd")


func test_first():
	# Entities register themselves to the server if they need to be replicated to the client.
	var dummy_entity = autofree(Node.new())
	assert_eq(1, 1)


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


func test_weapon_available():
	# Given a weapon pickup
	var weapon_pickup = add_child_autofree(WeaponPickup.instance())
	weapon_pickup.weapon = ViewModel.Weapon.SHOTGUN
	assert_eq(true, weapon_pickup.get_weapon_available())

	# When a player overlaps with the pickup
	var player = add_child_autofree(double(Player).instance())
	var area = weapon_pickup.get_node("Area")
	# TODO: Replace with moving player into area?
	area.emit_signal("body_entered", player)

	# Then the weapon is no longer available
	assert_eq(false, weapon_pickup.get_weapon_available())


func test_weapon_meshes_hidden_when_not_available():
	# Given a weapon pickup
	var weapon_pickup = add_child_autofree(WeaponPickup.instance())
	weapon_pickup.weapon = ViewModel.Weapon.SHOTGUN
	var shotgun_mesh = weapon_pickup.get_node("WeaponOrigin/ShotgunMesh")
	assert_eq(true, shotgun_mesh.visible)

	# When we mark the weapon as unavailable
	weapon_pickup.set_weapon_available(false)

	# Then the weapon meshes are hidden
	assert_eq(false, shotgun_mesh.is_visible_in_tree())


# NOTE: This should only run on the client!
func test_weapon_respawn():
	# Given a weapon pickup which is unavailable
	var weapon_pickup = add_child_autofree(WeaponPickup.instance())
	weapon_pickup.weapon = ViewModel.Weapon.SHOTGUN
	weapon_pickup.set_weapon_available(false)

	# When the respawn timer times out
	var respawn_timer = weapon_pickup.get_node("RespawnTimer")
	respawn_timer.emit_signal("timeout")

	# Then the weapon is available again
	assert_eq(true, weapon_pickup.get_weapon_available())
