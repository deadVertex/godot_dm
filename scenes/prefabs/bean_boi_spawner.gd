extends Node

export var max_bois: int = 4
export var bean_boi_scene: PackedScene


func _physics_process(delta: float):
	# Count current number of bois in scene
	var current_bean_bois = get_tree().get_nodes_in_group("bean_bois")

	# if less than max_bois
	if current_bean_bois.size() < max_bois:
		var bean_boi_spawns = get_tree().get_nodes_in_group("bean_boi_spawns")
		bean_boi_spawns.shuffle()
		var spawn_point = bean_boi_spawns.front()

		# spawn bois at spawn points
		var new_bean_boi = bean_boi_scene.instance()
		new_bean_boi.global_transform.origin = spawn_point.global_transform.origin
		get_tree().get_root().add_child(new_bean_boi)
