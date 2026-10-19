const AI_API_BASE = "http://localhost:8000/api";

export interface ChatHistoryItem {
  role: "user" | "assistant";
  content: string;
}

export const chatApi = {
  async streamAnswer(
    question: string,
    history: ChatHistoryItem[],
    onChunk: (chunk: string) => void,
    signal?: AbortSignal,
  ): Promise<void> {
    const response = await fetch(`${AI_API_BASE}/chat-rag/stream`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({
        question: question.trim(),
        history: history.slice(-15),
      }),
      signal,
    });

    if (!response.ok) {
      const body = await response.json().catch(() => null);
      throw new Error(body?.detail || "Chatbot chưa thể trả lời lúc này.");
    }
    if (!response.body) {
      throw new Error("Máy chủ chatbot không trả về dữ liệu.");
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder("utf-8");
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      const chunk = decoder.decode(value, { stream: true });
      if (chunk) onChunk(chunk);
    }
    const finalChunk = decoder.decode();
    if (finalChunk) onChunk(finalChunk);
  },
};
