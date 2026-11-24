const AI_API_BASE = (
  import.meta.env.VITE_AI_BASE_URL || "http://localhost:8000/api"
).replace(/\/+$/, "");

export interface ChatHistoryItem {
  role: "user" | "assistant";
  content: string;
  property_ids?: string[];
}

export interface ChatProperty {
  property_id: string;
  title: string;
  price_vnd: string;
  area_m2: string;
  district: string;
  ward: string;
  type: string;
}

function isChatProperty(value: unknown): value is ChatProperty {
  if (!value || typeof value !== "object") return false;
  const item = value as Record<string, unknown>;
  return typeof item.property_id === "string" && /^[1-9]\d*$/.test(item.property_id) &&
    ["title", "price_vnd", "area_m2", "district", "ward", "type"].every(
      (key) => typeof item[key] === "string",
    );
}

export const chatApi = {
  async streamAnswer(
    question: string,
    history: ChatHistoryItem[],
    onChunk: (chunk: string) => void,
    signal: AbortSignal,
  ): Promise<ChatProperty[]> {
    const timeout = AbortSignal.timeout(150_000);
    const requestSignal = AbortSignal.any([signal, timeout]);

    try {
      const response = await fetch(`${AI_API_BASE}/chat-rag/v2/stream`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          Accept: "text/event-stream",
        },
        body: JSON.stringify({
          question: question.trim(),
          history: history.slice(-15).map(({ role, content, property_ids }) => ({
            role,
            content: content.slice(0, 12000),
            property_ids: property_ids?.slice(0, 20),
          })),
        }),
        signal: requestSignal,
      });
      if (!response.ok) {
        const body = await response.json().catch(() => null);
        throw new Error(typeof body?.detail === "string" ? body.detail : "Chatbot chưa thể trả lời lúc này.");
      }
      if (!response.body || !response.headers.get("content-type")?.includes("text/event-stream")) {
        throw new Error("Chatbot trả về định dạng không hỗ trợ.");
      }

      const reader = response.body.pipeThrough(new TextDecoderStream()).getReader();
      let buffer = "";
      let properties: ChatProperty[] = [];
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          buffer += value;
          let separator = /\r?\n\r?\n/.exec(buffer);
          while (separator) {
            const frame = buffer.slice(0, separator.index);
            buffer = buffer.slice(separator.index + separator[0].length);
            const lines = frame.split(/\r?\n/);
            const event = lines.find((line) => line.startsWith("event:"))?.slice(6).trim();
            if (event === "done") return properties;
            if (event === "delta" || event === "properties" || event === "error") {
              const data = JSON.parse(lines.filter((line) => line.startsWith("data:"))
                .map((line) => line.slice(5).trimStart()).join("\n"));
              if (event === "error") {
                throw new Error(typeof data.message === "string" ? data.message : "Chatbot chưa thể trả lời lúc này.");
              }
              if (event === "delta" && typeof data.text === "string") onChunk(data.text);
              if (event === "properties" && Array.isArray(data.items)) {
                properties = data.items.filter(isChatProperty);
              }
            }
            separator = /\r?\n\r?\n/.exec(buffer);
          }
          if (buffer.length > 128_000) throw new Error("Phản hồi chatbot vượt giới hạn.");
        }
        throw new Error("Câu trả lời bị gián đoạn. Hãy gửi lại câu hỏi.");
      } finally {
        void reader.cancel().catch(() => {});
        reader.releaseLock();
      }
    } catch (error) {
      if (signal.aborted) throw error;
      if (timeout.aborted) throw new Error("Chatbot phản hồi quá lâu. Hãy thử lại.");
      if (error instanceof SyntaxError) throw new Error("Chatbot gửi phản hồi không hợp lệ.");
      if (error instanceof TypeError) throw new Error("Kết nối chatbot bị gián đoạn. Hãy thử lại.");
      throw error;
    }
  },
};
