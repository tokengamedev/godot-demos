extends Node

signal message_received(message: String, source: MessageSource)
signal chat_connection_changed(is_connected: bool)

enum MessageSource {
	SYSTEM, 	## System generated Messages
	USER, 	## Message sent from the User
	OTHERS 	## Message sent from Other Users
}

const PORT = 8000
const URL = "ws://localhost"

#var is_server : bool = false
var peer_name : String = ""
var partner_name: String = ""
var has_joined_chat : bool = false

var _peer := WebSocketMultiplayerPeer.new()


func set_user_name(user_name:String):
	peer_name = user_name
	set_partner_name.rpc(peer_name)


func _ready() -> void:
	_peer.supported_protocols = ["chat"]
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_disconnected)
	multiplayer.connection_failed.connect(_connecion_failed)
	multiplayer.connected_to_server.connect(_connected)


func create_chat_session():
	multiplayer.multiplayer_peer = null
	var error = _peer.create_server(PORT)
	if error != OK:
		print("Error: ",error)
	multiplayer.multiplayer_peer = _peer
	chat_connection_changed.emit(true)
	message_received.emit("-- Chat Started --", MessageSource.SYSTEM)


func join_chat_session():
	multiplayer.multiplayer_peer = null
	_peer.create_client(URL + ":" + str(PORT))
	multiplayer.multiplayer_peer = _peer
	chat_connection_changed.emit(true)
	message_received.emit("-- Connected to Chat --", MessageSource.SYSTEM)


func leave_chat_session():
	chat_connection_changed.emit(false)
	multiplayer.multiplayer_peer = null
	_peer.close()


## Sets the chat Partner Name
@rpc("any_peer")
func set_partner_name(_name:String):
	partner_name = _name
	message_received.emit("-- Connected to Partner %s --" % partner_name, MessageSource.SYSTEM)


## Sends Message to partner
@rpc("any_peer", "call_remote")
func send_message(message: String):
	if peer_name != partner_name:
		message_received.emit(message, MessageSource.OTHERS)


func debug(message:Variant):
	print(peer_name +"::" + str(message))


func _connected():
	debug("Connected to server")


func _disconnected():
	debug("Disconnected from server")
	leave_chat_session()


func _connecion_failed():
	debug("Connection failed")


func _peer_connected(peer_id: int):
	set_partner_name.rpc(peer_name)
	debug("Connected to peer:" + str(peer_id))


func _peer_disconnected(peer_id: int):
	message_received.emit("-- Partner %s Disconnected --" % partner_name, MessageSource.SYSTEM)
	debug("Disconnected to peer:" + str(peer_id))
	partner_name = ""
