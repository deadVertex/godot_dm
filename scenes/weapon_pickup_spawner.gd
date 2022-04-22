extends Node

# Just for enums...
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

export var world_path: NodePath
export var weapon_pickup_scene: PackedScene

var _world: Node

func _ready():
	if world_path:
		_world = get_node(world_path)


func spawn_weapon():
	print("spawn_weapon called")
	# Find all weapon spawns in world
	var spawns = get_tree().get_nodes_in_group("weapon_spawn")

	# Choose suitable spawn
	var selected_spawn = spawns.front()
	if selected_spawn:
		print("weapon spawn found")
		# Create weapon pickup entity at spawn location
		_create_weapon_pickup_entity(selected_spawn.global_transform.origin)


func _create_weapon_pickup_entity(position: Vector3):
	print("_create_weapon_pickup_entity called")
	# Create new weapon pickup at specified position
	var weapon_pickup = weapon_pickup_scene.instance()
	weapon_pickup.global_transform.origin = position
	weapon_pickup.weapon = ViewModel.Weapon.SHOTGUN
	
	# Add it to the world (note it is not tied to the spawn point
	# in any way)
	_world.add_child(weapon_pickup)
