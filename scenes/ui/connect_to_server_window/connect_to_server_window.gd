extends WindowDialog

signal connect_to_server(address, port)

onready var _address_line_edit: LineEdit = $GridContainer/AddressLineEdit
onready var _port_line_edit: LineEdit = $GridContainer/PortLineEdit


func _on_cancel_button_pressed():
	hide()


func _on_join_button_pressed():
	var server_address = _address_line_edit.text

	# TODO: validate that port number
	var server_port = int(_port_line_edit.text)

	emit_signal("connect_to_server", server_address, server_port)
