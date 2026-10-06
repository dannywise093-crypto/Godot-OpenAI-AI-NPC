# Godot OpenAI AI NPC + AI Builder

Phone-friendly Godot 4 project for an AI NPC plus a natural-language Godot project builder.

## Architecture

Godot Editor -> AI Builder plugin -> FastAPI backend -> OpenAI -> structured project plan -> safe Godot file writes

Android gameplay -> HTTPS backend -> OpenAI -> NPC response

The OpenAI API key stays on the backend. Never put it inside the Godot project or Android APK.

## AI Builder

1. Open the `godot/` folder in Godot 4.
2. Start the FastAPI backend.
3. Enable **AI Builder** under Project > Project Settings > Plugins.
4. Open the **Godot AI Builder** dock.
5. Enter a request such as: "Create a shop scene with lights, shelves and an NPC cashier."
6. Click **Build with AI**.

The builder returns a structured plan containing complete Godot project files. The editor plugin validates paths, writes allowed Godot files, and refreshes the filesystem.

## Backend

Copy `backend/.env.example` to `backend/.env` and set:

```
OPENAI_API_KEY=...
OPENAI_MODEL=...
```

Install and run:

```
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

Health check: `GET /health`

## Android

For a deployed Android build, use a deployed HTTPS backend URL instead of `127.0.0.1`. Keep the API key server-side.

## Safety boundary

The builder only accepts project-relative paths and allows Godot project text formats. It does not provide shell execution or arbitrary filesystem deletion.
