extends KinematicBody

export var health: int = 120


func apply_damage(amount: int):
	health = health - amount
	if health <= 0:
		queue_free()
