import asyncio
import hmac
import json
import logging
import os
import time
from collections import deque
from contextlib import aclosing
from threading import Lock

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse

from api.schemas import ChatRequest, ChatResponse
from rag.config import positive
from rag.pipeline import rag_service

log = logging.getLogger(__name__)
UNAVAILABLE = "Dịch vụ tư vấn tạm thời không khả dụng."
STREAM_HEADERS = {"Cache-Control": "no-cache, no-transform", "X-Accel-Buffering": "no"}
router = APIRouter(prefix="/api", tags=["Chatbot RAG"])
requests_in_window = deque()
rate_lock = Lock()
active_requests = 0


def admit_chat(request: Request):
    global active_requests
    gateway_token = os.getenv("CHAT_GATEWAY_TOKEN")
    if gateway_token and not hmac.compare_digest(
        request.headers.get("X-Chat-Gateway-Token", "").encode(), gateway_token.encode()
    ):
        raise HTTPException(status_code=401, detail="Yêu cầu chatbot chưa được xác thực.")
    limit = positive("CHAT_REQUESTS_PER_MINUTE", 60)
    concurrent = positive("CHAT_MAX_CONCURRENT_REQUESTS", 8)
    with rate_lock:
        now = time.monotonic()
        while requests_in_window and now - requests_in_window[0] >= 60:
            requests_in_window.popleft()
        if len(requests_in_window) >= limit:
            retry_after = max(1, int(60 - now + requests_in_window[0]) + 1) if requests_in_window else 60
            raise HTTPException(status_code=429, detail="Chatbot đang bận. Bạn hãy thử lại sau.",
                                headers={"Retry-After": str(retry_after)})
        if active_requests >= concurrent:
            raise HTTPException(status_code=429, detail="Chatbot đang xử lý nhiều yêu cầu. Hãy thử lại.",
                                headers={"Retry-After": "2"})
        requests_in_window.append(now)
        active_requests += 1
    try:
        yield
    finally:
        with rate_lock:
            active_requests -= 1


def validate_question(request):
    if not request.question.strip():
        raise HTTPException(status_code=400, detail="Câu hỏi không được để trống.")


@router.post("/chat-rag", response_model=ChatResponse, dependencies=[Depends(admit_chat)])
def chat_endpoint(request: ChatRequest):
    validate_question(request)
    try:
        return ChatResponse(answer=rag_service.query(request.question, history=request.history))
    except Exception as error:
        log.error("chat status=failed reason=%s", type(error).__name__)
        raise HTTPException(status_code=503, detail=UNAVAILABLE) from None


@router.post("/chat-rag/stream", dependencies=[Depends(admit_chat)])
async def chat_stream_endpoint(request: ChatRequest):
    validate_question(request)

    async def tokens():
        try:
            async for token in rag_service.query_astream(request.question, history=request.history):
                yield token
        except Exception as error:
            log.error("chat_stream status=failed reason=%s", type(error).__name__)
            yield f"\n[{UNAVAILABLE}]"

    return StreamingResponse(tokens(), media_type="text/plain", headers=STREAM_HEADERS)


def sse(event, data):
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


@router.post("/chat-rag/v2/stream", dependencies=[Depends(admit_chat)])
async def chat_v2_stream_endpoint(request: ChatRequest):
    validate_question(request)

    async def events():
        has_text = False
        try:
            async with aclosing(rag_service.stream_events(request.question, history=request.history)) as stream:
                deadline = time.monotonic() + 140
                while True:
                    try:
                        kind, value = await asyncio.wait_for(anext(stream), deadline - time.monotonic())
                    except StopAsyncIteration:
                        break
                    if kind == "delta" and value:
                        has_text = has_text or bool(value.strip())
                        yield sse("delta", {"text": value})
                    elif kind == "properties":
                        if not has_text:
                            raise ValueError("Empty answer")
                        yield sse("properties", {"items": value})
            if not has_text:
                raise ValueError("Empty answer")
            yield sse("done", {})
        except asyncio.TimeoutError:
            yield sse("error", {"code": "timeout", "message": "Chatbot phản hồi quá lâu. Hãy thử lại."})
        except Exception as error:
            log.error("chat_v2_stream status=failed reason=%s", type(error).__name__)
            yield sse("error", {"code": "unavailable", "message": UNAVAILABLE})

    return StreamingResponse(events(), media_type="text/event-stream", headers=STREAM_HEADERS)
