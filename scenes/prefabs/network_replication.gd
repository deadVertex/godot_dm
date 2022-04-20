extends Node

signal network_event(event)

const Player = preload("res://scenes/prefabs/player.gd")

export var body_path: NodePath
export var register_with_replication_server: bool = true  # This is set to false on client

var _body: Player


func _ready():
	if body_path:
		_body = get_node(body_path)

	# Register with replication server
	if register_with_replication_server:
		var replication_server = get_tree().get_root().get_node(
			"Main/ReplicationServer"
		)
		if replication_server:
			replication_server.register_entity(self)

		# Capture bullet impact signal and convert to network event
		var error = _body.connect("bullet_impact", self, "_on_bullet_impact")
		assert(error == OK)
		# print("_body.connect bullet_impact")


func get_initial_state():
	var initial_state = {"position": _body.global_transform.origin}
	return initial_state


func set_initial_state(initial_state):
	_body.global_transform.origin = initial_state["position"]


func get_state():
	var state = {
		"position": _body.global_transform.origin,
		"view_model_animation": _body.view_model_animation,
		"weapon": _body.get_view_model()
	}
	return state


func set_state(state):
	_body.global_transform.origin = state["position"]
	_body.set_view_model_animation(state["view_model_animation"])
	_body.set_view_model(state["weapon"])


func _on_bullet_impact(position: Vector3, normal: Vector3):
	# print("_on_bullet_impact")
	# Create network event for the bullet impact signal we received from the
	# player body and emit another signal to pass the event up to the
	# replication server
	var event = {
		"type": "bullet_impact", "position": position, "normal": normal
	}
	# print("emit_signal: network_event")
	emit_signal("network_event", event)
