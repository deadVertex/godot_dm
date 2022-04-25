extends Spatial

const Player = preload("res://scenes/prefabs/player.gd")
# Just for enums...
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

export(ViewModel.Weapon) var weapon = ViewModel.Weapon.UZI

var is_server := true

func _on_area_body_entered(body: Player) -> void:
	if is_server:
		if body is Player:
			body.give_weapon(weapon)
			queue_free()
