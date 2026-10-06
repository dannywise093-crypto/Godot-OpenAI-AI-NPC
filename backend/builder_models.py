from pydantic import BaseModel, Field
from typing import Literal

class BuilderRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=12000)
    project_context: str = Field(default="", max_length=12000)

class BuilderOperation(BaseModel):
    action: Literal["create", "update"]
    path: str = Field(min_length=1, max_length=240)
    content: str = Field(max_length=200000)
    reason: str = Field(default="", max_length=500)

class BuilderPlan(BaseModel):
    summary: str
    operations: list[BuilderOperation]
    warnings: list[str] = []
