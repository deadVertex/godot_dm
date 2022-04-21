extends Spatial

const Player = preload("res://scenes/prefabs/player.gd")
# Just for enums...
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

export var weapon: int = ViewModel.Weapon.UZI

var _weapon_available := true

onready var _weapon_origin: Spatial = $WeaponOrigin


func _on_area_body_entered(body: Player) -> void:
	if body is Player:
		body.give_weapon(weapon)
		set_weapon_available(false)


func set_weapon_available(available: bool) -> void:
	_weapon_available = available
	_weapon_origin.visible = available


func get_weapon_available() -> bool:
	return _weapon_available


func _on_respawn_timer_timeout() -> void:
	print("_on_respawn_timer_timeout")
	set_weapon_available(true)
