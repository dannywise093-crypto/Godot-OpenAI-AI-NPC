import json
import re
from openai import OpenAI
from builder_models import BuilderPlan

SYSTEM_PROMPT = r"""
You are the Godot AI Builder for a Godot 4.x project.
Convert the user's natural-language request into a small, runnable set of project-file operations.

Return ONLY valid JSON:
{"summary":"short description","operations":[{"action":"create|update","path":"relative/path","content":"complete file content","reason":"why"}],"warnings":[]}

Rules:
- Target Godot 4.x.
- Paths are relative to the Godot project root and use forward slashes.
- Only generate project files; never use shell commands.
- Prefer small reusable GDScript files and scenes.
- Existing project files may be updated when required.
- Never include API keys, passwords, tokens, or other secrets.
- Never generate code that deletes arbitrary files, executes shell commands, downloads unknown executables, or bypasses permissions.
- Include all required scripts/resources so the requested result is runnable.
- Keep changes focused; do not rewrite unrelated files.
"""

def _extract_json(text: str) -> dict:
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", text, flags=re.DOTALL)
        if not match:
            raise ValueError("AI did not return a JSON builder plan")
        return json.loads(match.group(0))

def generate_plan(client: OpenAI, model: str, request: dict) -> BuilderPlan:
    user_prompt = "USER REQUEST:\n" + request["prompt"] + "\n\nCURRENT PROJECT CONTEXT:\n" + request.get("project_context", "")
    response = client.responses.create(model=model, instructions=SYSTEM_PROMPT, input=user_prompt)
    plan = BuilderPlan.model_validate(_extract_json(response.output_text))
    for operation in plan.operations:
        if operation.path.startswith("/") or ".." in operation.path.split("/"):
            raise ValueError(f"Unsafe project path: {operation.path}")
        if not operation.path.endswith((".gd", ".tscn", ".tres", ".cfg", ".json", ".md")):
            raise ValueError(f"Unsupported project file type: {operation.path}")
    return plan
