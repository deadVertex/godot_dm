class_name NetworkReplication
extends Node

signal network_event(event)
signal network_entity_deleted(id)

enum EntityType { PLAYER, OTHER }

const Player = preload("res://scenes/prefabs/player.gd")
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

export(NodePath) var body_path
export(NodePath) var view_model_path
export(NodePath) var root_path
export(bool) var register_with_replication_server = true  # This is set to false on client
export(EntityType) var entity_type = EntityType.PLAYER

var _id: int = 0

onready var _body: Player = get_node(body_path)
onready var _view_model: ViewModel = get_node(view_model_path)
onready var _root: Spatial = get_node(root_path)


func _ready():
	# Register with replication server
	if register_with_replication_server:
		var replication_server = get_tree().get_root().get_node(
			"Main/ReplicationServer"
		)
		if replication_server:
			replication_server.register_entity(self)

		if entity_type == EntityType.PLAYER:
			# Capture bullet impact signal and convert to network event
			var error = _body.connect(
				"bullet_impact", self, "_on_bullet_impact"
			)
			assert(error == OK)
			# print("_body.connect bullet_impact")


func get_initial_state():
	var initial_state = {}
	match entity_type:
		EntityType.PLAYER:
			initial_state = {
				"type": EntityType.PLAYER,
				"position": _body.global_transform.origin
			}
		EntityType.OTHER:
			initial_state = {
				"type": EntityType.OTHER,
				"position": _root.global_transform.origin
			}

	return initial_state


func set_initial_state(initial_state):
	match entity_type:
		EntityType.PLAYER:
			_body.global_transform.origin = initial_state["position"]
		EntityType.OTHER:
			_root.global_transform.origin = initial_state["position"]


func get_state():
	if entity_type == EntityType.PLAYER:
		var state = {
			"position": _body.global_transform.origin,
			"view_model_animation": _body.get_current_view_model_animation(),
			"weapon": _body.get_active_weapon()
		}
		return state


func set_state(state):
	# print("set_state: %s" % state)
	if entity_type == EntityType.PLAYER:
		_body.global_transform.origin = state["position"]
		_view_model.set_weapon(state["weapon"])
		_view_model.set_animation(state["view_model_animation"])


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


func set_id(id: int) -> void:
	assert(_id == 0)
	_id = id


func get_id() -> int:
	return _id
