extends CanvasLayer

@export var npc_path: NodePath

@onready var npc: AINPC = get_node(npc_path)
@onready var chat_log: RichTextLabel = $Panel/VBoxContainer/ChatLog
@onready var input: LineEdit = $Panel/VBoxContainer/Input
@onready var send_button: Button = $Panel/VBoxContainer/SendButton


func _ready() -> void:
    npc.npc_spoke.connect(_on_npc_spoke)
    npc.npc_error.connect(_on_npc_error)
    send_button.pressed.connect(_send_message)
    input.text_submitted.connect(_on_text_submitted)


func _send_message() -> void:
    var message := input.text.strip_edges()
    if message.is_empty():
        return

    chat_log.append_text("\n[b]You:[/b] " + message)
    input.clear()
    npc.talk(message)


func _on_text_submitted(_text: String) -> void:
    _send_message()


func _on_npc_spoke(text: String) -> void:
    chat_log.append_text("\n[b]" + npc.npc_name + ":[/b] " + text)


func _on_npc_error(message: String) -> void:
    chat_log.append_text("\n[color=red][b]Error:[/b] " + message + "[/color]")
