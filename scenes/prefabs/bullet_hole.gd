extends Spatial

onready var _particles = $CPUParticles

func _ready():
	_particles.restart()
