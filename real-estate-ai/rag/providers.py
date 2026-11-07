import os


def create_embedding(settings):
    from langchain_google_genai import GoogleGenerativeAIEmbeddings
    if not settings.google_api_key:
        raise ValueError("Missing GOOGLE_API_KEY")
    return GoogleGenerativeAIEmbeddings(model=settings.embedding_model, google_api_key=settings.google_api_key)


def create_llm(settings):
    common = dict(temperature=0.0, timeout=120, max_retries=0,
                  max_tokens=settings.max_output_tokens)
    if settings.llm_provider == "gemini":
        from langchain_google_genai import ChatGoogleGenerativeAI
        if not settings.google_api_key or not settings.llm_model or settings.llm_model.startswith("REPLACE"):
            raise ValueError("Set GOOGLE_API_KEY and verified GEMINI_LLM_MODEL")
        return ChatGoogleGenerativeAI(model=settings.llm_model, api_key=settings.google_api_key,
                                     vertexai=False, temperature=0.0, retries=0,
                                     request_timeout=120, max_tokens=settings.max_output_tokens)
    from langchain_openai import ChatOpenAI
    if not all(os.getenv(k) for k in ("AI_API_KEY", "AI_MODEL", "AI_BASE_URL")):
        raise ValueError("Legacy requires AI_API_KEY, AI_MODEL, AI_BASE_URL")
    return ChatOpenAI(model=os.environ["AI_MODEL"], api_key=os.environ["AI_API_KEY"],
                      base_url=os.environ["AI_BASE_URL"], **common)
