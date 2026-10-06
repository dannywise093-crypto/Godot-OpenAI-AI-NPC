class_name AINPC
extends Node

@export var npc_name := "Alex"
@export_multiline var personality := "Friendly, helpful, and familiar with the local game world."
@export var location := "Downtown"

var previous_response_id := ""

signal npc_spoke(text: String)
signal npc_error(message: String)


func _ready() -> void:
    AIClient.response_received.connect(_on_ai_response)
    AIClient.request_failed.connect(_on_ai_error)


func talk(player_message: String) -> void:
    AIClient.ask_npc(
        npc_name,
        player_message,
        location,
        personality,
        previous_response_id
    )


func _on_ai_response(text: String, response_id: String) -> void:
    previous_response_id = response_id
    npc_spoke.emit(text)


func _on_ai_error(message: String) -> void:
    npc_error.emit(message)
