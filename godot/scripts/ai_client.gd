extends Node

signal response_received(text: String, response_id: String)
signal request_failed(message: String)

@export var backend_url := "http://127.0.0.1:8000"
@export var request_timeout := 30.0

var http: HTTPRequest

func _ready() -> void:
    http = HTTPRequest.new()
    http.timeout = request_timeout
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
        request_failed.emit("An AI request is already running. Please wait for it to finish.")
        return

    if backend_url.strip_edges().is_empty():
        request_failed.emit("AI backend URL is empty. Set AIClient.backend_url.")
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
        backend_url.trim_suffix("/") + "/npc/chat",
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
        if result == HTTPRequest.RESULT_CANT_CONNECT:
            request_failed.emit(
                "Cannot reach the AI backend. On Android, 127.0.0.1 points to the phone itself. " +
                "Use your deployed HTTPS backend URL in AIClient.backend_url."
            )
        elif result == HTTPRequest.RESULT_TIMEOUT:
            request_failed.emit("AI backend timed out. Check that the backend is running and reachable.")
        else:
            request_failed.emit("Network request failed: " + str(result))
        return

    var raw := body.get_string_from_utf8()
    var json := JSON.new()
    if json.parse(raw) != OK:
        request_failed.emit("Backend returned invalid JSON (HTTP %d)." % response_code)
        return

    var data = json.data

    if response_code < 200 or response_code >= 300:
        request_failed.emit(str(data.get("detail", "Backend error (HTTP %d)" % response_code)))
        return

    response_received.emit(
        str(data.get("text", "")),
        str(data.get("response_id", ""))
    )
