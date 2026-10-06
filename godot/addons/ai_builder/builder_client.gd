@tool
extends Node

signal plan_received(plan: Dictionary)
signal request_failed(message: String)

@export var backend_url := "http://127.0.0.1:8000"
var http: HTTPRequest

func _ready() -> void:
    http = HTTPRequest.new()
    http.timeout = 45.0
    add_child(http)
    http.request_completed.connect(_on_request_completed)

func plan(prompt: String, project_context: String = "") -> void:
    var payload := JSON.stringify({"prompt": prompt, "project_context": project_context})
    var headers := PackedStringArray(["Content-Type: application/json"])
    var error := http.request(backend_url + "/builder/plan", headers, HTTPClient.METHOD_POST, payload)
    if error != OK:
        request_failed.emit(error_string(error))

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS:
        request_failed.emit("Network request failed: " + str(result))
        return
    var json := JSON.new()
    if json.parse(body.get_string_from_utf8()) != OK:
        request_failed.emit("Builder returned invalid JSON.")
        return
    var data = json.data
    if response_code < 200 or response_code >= 300:
        request_failed.emit(str(data.get("detail", "Builder backend error")))
        return
    plan_received.emit(data)
