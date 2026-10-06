class_name AIClient
extends Node

signal response_received(text: String, response_id: String)
signal request_failed(message: String)

@export var backend_url := "http://127.0.0.1:8000"

var http: HTTPRequest


func _ready() -> void:
    http = HTTPRequest.new()
    http.timeout = 15.0
    add_child(http)
    http.request_completed.connect(_on_request_completed)


func ask_npc(
    npc_name: String,
    player_message: String,
    location: String,
    personality: String,
    previous_response_id: String = ""
) -> void:
    if http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        request_failed.emit("An AI request is already running.")
        return

    var payload := {
        "npc_name": npc_name,
        "player_message": player_message,
        "location": location,
        "personality": personality
    }

    if previous_response_id != "":
        payload["previous_response_id"] = previous_response_id

    var headers := PackedStringArray(["Content-Type: application/json"])
    var body := JSON.stringify(payload)

    var error := http.request(
        backend_url + "/npc/chat",
        headers,
        HTTPClient.METHOD_POST,
        body
    )

    if error != OK:
        request_failed.emit("Could not start AI request: " + error_string(error))


func _on_request_completed(
    result: int,
    response_code: int,
    _headers: PackedStringArray,
    body: PackedByteArray
) -> void:
    if result != HTTPRequest.RESULT_SUCCESS:
        request_failed.emit("Network request failed: " + str(result))
        return

    var json := JSON.new()
    if json.parse(body.get_string_from_utf8()) != OK:
        request_failed.emit("Backend returned invalid JSON.")
        return

    var data = json.data

    if response_code < 200 or response_code >= 300:
        request_failed.emit(str(data.get("detail", "Backend error")))
        return

    response_received.emit(
        str(data.get("text", "")),
        str(data.get("response_id", ""))
    )
