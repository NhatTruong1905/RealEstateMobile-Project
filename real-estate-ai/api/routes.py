from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from api.schemas import ChatRequest, ChatResponse
from rag.pipeline import rag_service

router = APIRouter(prefix="/api", tags=["Chatbot RAG"])


@router.post("/chat-rag", response_model=ChatResponse)
def chat_endpoint(request: ChatRequest):
    if not request.question.strip():
        raise HTTPException(status_code=400, detail="Câu hỏi không được để trống.")

    try:
        answer = rag_service.query(request.question, history=request.history)
        return ChatResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi hệ thống RAG: {str(e)}")


@router.post("/chat-rag/stream")
async def chat_stream_endpoint(request: ChatRequest):
    if not request.question.strip():
        raise HTTPException(status_code=400, detail="Câu hỏi không được để trống.")

    async def token_generator():
        try:
            async for token in rag_service.query_astream(request.question, history=request.history):
                yield token
        except Exception as e:
            yield f"\n[Lỗi hệ thống RAG: {str(e)}]"

    return StreamingResponse(
        token_generator(),
        media_type="text/plain; charset=utf-8"
    )


# @router.post("/chat-rag/stream-sse")
# async def chat_sse_endpoint(request: ChatRequest):
#     if not request.question.strip():
#         raise HTTPException(status_code=400, detail="Câu hỏi không được để trống.")
#
#     async def sse_generator():
#         try:
#             async for token in rag_service.query_astream(request.question):
#                 clean_token = token.replace("\n", "\\n")
#                 yield f"data: {clean_token}\n\n"
#             yield "data: [DONE]\n\n"
#         except Exception as e:
#             yield f"data: [ERROR: {str(e)}]\n\n"
#
#     return StreamingResponse(
#         sse_generator(),
#         media_type="text/event-stream"
#     )
