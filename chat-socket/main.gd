extends Control

@onready var chat_window: RichTextLabel = $VBoxContainer/ChatWindow
@onready var message_edit: LineEdit = $VBoxContainer/HBoxContainer/Message
@onready var chat_users: Node = $ChatUsers
@onready var name_edit: LineEdit = $NameContainer/NameEdit
@onready var start_chat: Button = $Action/StartChat
@onready var join_chat: Button = $Action/JoinChat
@onready var leave_chat: Button = $Action/LeaveChat

const MessageSource := ChatManager.MessageSource


const TEXT_FORMATS := {
	MessageSource.SYSTEM :  "[center][color='666']%s[/color][/center]",
	MessageSource.OTHERS : "[left]%s: [color='3e9bc2']%s[/color][/left]",
	MessageSource.USER : "[right][color='fabe7d']%s[/color][/right]"
}

var user_name := ""
var id := 0
func _enter_tree() -> void:
	id = (randi() % 900) + 100
	user_name = "Player%d" % id
	ChatManager.set_user_name(user_name)
	ChatManager.message_received.connect(_on_message_received)
	ChatManager.chat_connection_changed.connect(_on_chat_connection_changed)

func _ready() -> void:
	chat_window.text = ""
	name_edit.text = user_name


func write_to_chat(text: String, source: MessageSource):
	if source == MessageSource.OTHERS:
		chat_window.text += TEXT_FORMATS[source] % [ChatManager.partner_name, text]
	else:
		chat_window.text += TEXT_FORMATS[source] % text


func _on_send_pressed() -> void:
	_on_message_text_submitted(message_edit.text)
	message_edit.grab_focus()


func _on_message_text_submitted(_new_text: String) -> void:
	write_to_chat(message_edit.text, MessageSource.USER)
	# send message to others
	ChatManager.send_message.rpc(message_edit.text)
	message_edit.text = ""


func _on_message_received(message: String, source: MessageSource):
	write_to_chat(message, source)


func _on_chat_connection_changed(is_connected_to_chat: bool):
	start_chat.visible = not is_connected_to_chat
	join_chat.visible = not is_connected_to_chat
	leave_chat.visible = is_connected_to_chat


func _on_start_chat_pressed() -> void:
	ChatManager.create_chat_session()


func _on_join_chat_pressed() -> void:
	ChatManager.join_chat_session()


func _on_leave_chat_pressed() -> void:
	ChatManager.leave_chat_session()


func _on_update_name_pressed() -> void:
	ChatManager.set_user_name(name_edit.text)
