from pydantic import BaseModel, Field

class ChatRequest(BaseModel):
    question: str = Field(..., example="Chào bạn?")

class ChatResponse(BaseModel):
    answer: str