from typing import List, Optional
from pydantic import BaseModel, Field

class MessageItem(BaseModel):
    role: str = Field(..., example="user")
    content: str = Field(..., example="Tôi muốn tìm nhà Quận 1")

class ChatRequest(BaseModel):
    question: str = Field(..., example="Chào bạn?")
    history: Optional[List[MessageItem]] = Field(default=None, description="Lịch sử trò chuyện trước đó")

class ChatResponse(BaseModel):
    answer: str
