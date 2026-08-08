from fastapi import APIRouter, HTTPException
from api.schemas import ChatRequest, ChatResponse
from rag.pipeline import rag_service

router = APIRouter(prefix="/api", tags=["Chatbot RAG"])


@router.post("/chat-rag", response_model=ChatResponse)
def chat_endpoint(request: ChatRequest):
    if not request.question.strip():
        raise HTTPException(status_code=400, detail="Câu hỏi không được để trống.")

    try:
        answer = rag_service.query(request.question)
        return ChatResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi hệ thống RAG: {str(e)}")
