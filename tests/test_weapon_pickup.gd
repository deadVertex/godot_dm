extends "res://addons/gut/test.gd"

const WeaponPickup = preload("res://scenes/prefabs/weapon_pickup.tscn")
const Player = preload("res://scenes/prefabs/player.tscn")
# Just for enums...
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

func test_first():
	# Entities register themselves to the server if they need to be replicated to the client.
	var dummy_entity = autofree(Node.new())
	assert_eq(1,1)

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
