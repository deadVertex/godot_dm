extends Spatial

enum ViewModelAnimation { IDLE, FIRE }
enum Weapon { UZI, SHOTGUN } # TODO: Move away from fix enum for weapons

var _visible_weapon: int = Weapon.UZI

onready var _animation_player: AnimationPlayer = $AnimationPlayer
onready var _uzi: Spatial = $UziBase
onready var _shotgun: Spatial = $ShotgunBase

func set_weapon(weapon: int) -> void:
	_visible_weapon = weapon
	if weapon == Weapon.UZI:
		_uzi.show()
		_shotgun.hide()
	elif weapon == Weapon.SHOTGUN:
		_uzi.hide()
		_shotgun.show()


func set_animation(animation: int) -> void:
	assert(animation in ViewModelAnimation.values())
	if animation == ViewModelAnimation.IDLE:
		if _visible_weapon == Weapon.UZI:
			_animation_player.play("Uzi_Idle")
		elif _visible_weapon == Weapon.SHOTGUN:
			_animation_player.play("Shotgun_Idle")
	elif animation == ViewModelAnimation.FIRE:
		if _visible_weapon == Weapon.UZI:
			_animation_player.play("Uzi_Fire")
		elif _visible_weapon == Weapon.SHOTGUN:
			_animation_player.play("Shotgun_Fire")


