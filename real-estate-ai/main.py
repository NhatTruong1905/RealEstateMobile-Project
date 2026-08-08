from contextlib import asynccontextmanager
from fastapi import FastAPI
from api.routes import router as api_router
from rag.pipeline import rag_service

@asynccontextmanager
async def lifespan(app: FastAPI):
    rag_service.initialize()
    yield

app = FastAPI(
    title="Real Estate RAG API",
    version="1.0.0",
    lifespan=lifespan
)

app.include_router(api_router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)