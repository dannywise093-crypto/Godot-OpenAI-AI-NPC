import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel, Field

from builder import generate_plan
from builder_models import BuilderRequest, BuilderPlan

load_dotenv()
API_KEY = os.getenv("OPENAI_API_KEY", "").strip()
MODEL = os.getenv("OPENAI_MODEL", "").strip()

# Keep startup working so the API can return a useful configuration error to Godot.
client = OpenAI(api_key=API_KEY) if API_KEY else None

app = FastAPI(title="Godot OpenAI AI NPC + AI Builder")


class NPCRequest(BaseModel):
    npc_name: str = Field(min_length=1, max_length=80)
    player_message: str = Field(min_length=1, max_length=4000)
    location: str = Field(default="unknown", max_length=200)
    personality: str = Field(default="friendly", max_length=2000)
    previous_response_id: str | None = None


class NPCResponse(BaseModel):
    text: str
    response_id: str


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "openai_api_key": "configured" if API_KEY else "missing",
        "openai_model": "configured" if MODEL else "missing",
    }


def _require_openai_config() -> OpenAI:
    if not API_KEY:
        raise HTTPException(
            status_code=503,
            detail="OpenAI API key missing. Set OPENAI_API_KEY in backend/.env and restart the backend.",
        )
    if not MODEL:
        raise HTTPException(
            status_code=503,
            detail="OpenAI model missing. Set OPENAI_MODEL in backend/.env and restart the backend.",
        )
    return OpenAI(api_key=API_KEY)


@app.post("/npc/chat", response_model=NPCResponse)
def npc_chat(request: NPCRequest) -> NPCResponse:
    instructions = f"""You are {request.npc_name}, an AI-controlled NPC in a video game.
Personality:
{request.personality}
Current location:
{request.location}
Stay in character, respond naturally and concisely, and treat the player as a character inside the game."""
    openai_client = _require_openai_config()
    try:
        kwargs = {"model": MODEL, "instructions": instructions, "input": request.player_message}
        if request.previous_response_id:
            kwargs["previous_response_id"] = request.previous_response_id
        response = openai_client.responses.create(**kwargs)
        return NPCResponse(text=response.output_text, response_id=response.id)
    except Exception as exc:
        if getattr(exc, "status_code", None) == 401:
            raise HTTPException(
                status_code=502,
                detail="OpenAI API key is invalid or unauthorized. Check OPENAI_API_KEY in backend/.env.",
            ) from exc
        raise HTTPException(status_code=502, detail="AI provider request failed") from exc


@app.post("/builder/plan", response_model=BuilderPlan)
def builder_plan(request: BuilderRequest) -> BuilderPlan:
    openai_client = _require_openai_config()
    try:
        return generate_plan(openai_client, MODEL, request.model_dump())
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        if getattr(exc, "status_code", None) == 401:
            raise HTTPException(
                status_code=502,
                detail="OpenAI API key is invalid or unauthorized. Check OPENAI_API_KEY in backend/.env.",
            ) from exc
        raise HTTPException(status_code=502, detail="AI builder request failed") from exc
