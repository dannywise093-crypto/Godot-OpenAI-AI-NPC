# Godot-OpenAI-AI-NPC

A phone-friendly Godot 4 starter project for connecting an AI NPC to OpenAI through a small FastAPI backend.

## Architecture

Godot Android -> HTTPS backend -> OpenAI Responses API -> NPC response

The OpenAI API key stays on the backend. Do not put an OpenAI API key inside the Godot project or Android APK.

## Repository layout

- `godot/` - Godot project, NPC controller, HTTP client, and starter chat scene.
- `backend/` - FastAPI service that talks to OpenAI.
- `.env.example` - backend configuration template.

## Backend setup

Copy `backend/.env.example` to `backend/.env` and set:

```text
OPENAI_API_KEY=...
OPENAI_MODEL=...
```

Install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

Check:

```text
GET /health
```

Expected response:

```json
{"status":"ok"}
```

## Godot setup

Open the `godot/` directory as a Godot project.

The starter scene is:

```text
Main
├── NPC_Alex
└── ChatUI
```

The NPC controller uses the autoloaded `AIClient`.

For Android, enable the Godot Android export `INTERNET` permission before using the networked NPC.

## Android deployment

Do not use `127.0.0.1` for a deployed Android build unless the backend is actually running on the same phone. For a real phone deployment, set `AIClient.backend_url` to your deployed HTTPS backend.

## Planned upgrades

1. Structured NPC actions
2. Persistent game memory
3. Quests and world-state tools
4. NavigationAgent3D movement
5. Voice input/output
6. Multiple NPCs
7. NPC relationship and reputation systems

## Security

Never commit `backend/.env` or API keys. Use server-side secrets and HTTPS in production.
