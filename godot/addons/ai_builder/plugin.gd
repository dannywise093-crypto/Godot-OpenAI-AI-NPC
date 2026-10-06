@tool
extends EditorPlugin

var dock: Control
var prompt_box: TextEdit
var context_box: TextEdit
var output_box: RichTextLabel
var generate_button: Button
var client: Node

func _enter_tree() -> void:
    client = preload("res://addons/ai_builder/builder_client.gd").new()
    add_child(client)
    client.plan_received.connect(_on_plan_received)
    client.request_failed.connect(_on_request_failed)
    dock = preload("res://addons/ai_builder/builder_dock.tscn").instantiate()
    prompt_box = dock.get_node("Margin/VBox/Prompt")
    context_box = dock.get_node("Margin/VBox/Context")
    output_box = dock.get_node("Margin/VBox/Output")
    generate_button = dock.get_node("Margin/VBox/Generate")
    generate_button.pressed.connect(_generate)
    add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)

func _exit_tree() -> void:
    if dock:
        remove_control_from_docks(dock)
        dock.queue_free()
    if client:
        client.queue_free()

func _generate() -> void:
    var prompt := prompt_box.text.strip_edges()
    if prompt.is_empty():
        output_box.text = "Enter a request first."
        return
    generate_button.disabled = true
    output_box.text = "Planning project changes..."
    client.plan(prompt, context_box.text)

func _on_plan_received(plan: Dictionary) -> void:
    generate_button.disabled = false
    var applied := 0
    var warnings: Array = plan.get("warnings", [])
    for operation in plan.get("operations", []):
        var path := str(operation.get("path", ""))
        var content := str(operation.get("content", ""))
        if _is_safe_path(path) and _write_project_file(path, content):
            applied += 1
    get_editor_interface().get_resource_filesystem().scan()
    output_box.text = "%s\nApplied %d file operation(s)." % [str(plan.get("summary", "Done.")), applied]
    if not warnings.is_empty():
        output_box.text += "\nWarnings:\n- " + "\n- ".join(PackedStringArray(warnings))

func _on_request_failed(message: String) -> void:
    generate_button.disabled = false
    output_box.text = "Builder error: " + message

func _is_safe_path(path: String) -> bool:
    if path.is_empty() or path.begins_with("/") or path.contains(".."):
        return false
    return path.ends_with(".gd") or path.ends_with(".tscn") or path.ends_with(".tres") or path.ends_with(".cfg") or path.ends_with(".json") or path.ends_with(".md")

func _write_project_file(relative_path: String, content: String) -> bool:
    var absolute := ProjectSettings.globalize_path("res://" + relative_path)
    DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
    var file := FileAccess.open(absolute, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(content)
    file.close()
    return true
