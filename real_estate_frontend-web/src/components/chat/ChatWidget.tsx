import { useEffect, useRef, useState } from "react";
import { Bot, LoaderCircle, MessageCircle, Send, Trash2, X } from "lucide-react";
import { chatApi, type ChatHistoryItem } from "../../services/api/chat/chatApi";

interface ChatMessage extends ChatHistoryItem {
  id: string;
  isError?: boolean;
}

const STORAGE_KEY = "real-estate-web-chat-history";
const WELCOME_MESSAGE: ChatMessage = {
  id: "welcome",
  role: "assistant",
  content:
    "Chào bạn, tôi là trợ lý Nhà Việt. Bạn đang tìm mua hay thuê bất động sản ở khu vực nào?",
};

function loadHistory(): ChatMessage[] {
  try {
    const stored = JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]");
    return Array.isArray(stored) && stored.length ? stored : [WELCOME_MESSAGE];
  } catch {
    return [WELCOME_MESSAGE];
  }
}

export function ChatWidget() {
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>(loadHistory);
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const endRef = useRef<HTMLDivElement>(null);
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    if (messages.every((message) => message.id === "welcome")) {
      localStorage.removeItem(STORAGE_KEY);
    } else {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(messages.slice(-30)));
    }
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  useEffect(() => {
    function resetSession() {
      abortRef.current?.abort();
      abortRef.current = null;
      setSending(false);
      setMessages([WELCOME_MESSAGE]);
      setDraft("");
      setOpen(false);
    }
    function syncLogout(event: StorageEvent) {
      if (event.storageArea === localStorage &&
          (event.key === null || (event.key === "real-estate-web-token" && event.newValue === null))) {
        resetSession();
      }
    }
    window.addEventListener("session-cleared", resetSession);
    window.addEventListener("storage", syncLogout);
    return () => {
      window.removeEventListener("session-cleared", resetSession);
      window.removeEventListener("storage", syncLogout);
    };
  }, []);

  useEffect(() => {
    if (open) window.setTimeout(() => inputRef.current?.focus(), 80);
  }, [open]);

  useEffect(() => {
    function closeOnEscape(event: KeyboardEvent) {
      if (event.key === "Escape") setOpen(false);
    }
    window.addEventListener("keydown", closeOnEscape);
    return () => {
      window.removeEventListener("keydown", closeOnEscape);
      abortRef.current?.abort();
    };
  }, []);

  async function sendMessage() {
    const question = draft.trim();
    if (!question || sending) return;

    const userMessage: ChatMessage = {
      id: `user-${Date.now()}`,
      role: "user",
      content: question,
    };
    const assistantId = `assistant-${Date.now()}`;
    const history = messages
      .filter((message) => message.id !== "welcome" && !message.isError)
      .map(({ role, content }) => ({ role, content }));

    setDraft("");
    setSending(true);
    setMessages((current) => [
      ...current,
      userMessage,
      { id: assistantId, role: "assistant", content: "" },
    ]);

    const controller = new AbortController();
    abortRef.current = controller;
    try {
      await chatApi.streamAnswer(
        question,
        history,
        (chunk) => {
          if (controller.signal.aborted) return;
          setMessages((current) =>
            current.map((message) =>
              message.id === assistantId
                ? { ...message, content: message.content + chunk }
                : message,
            ),
          );
        },
        controller.signal,
      );
    } catch (error) {
      if (controller.signal.aborted) return;
      setMessages((current) =>
        current.map((message) =>
          message.id === assistantId
            ? {
                ...message,
                isError: true,
                content:
                  error instanceof Error
                    ? error.message
                    : "Không thể kết nối chatbot. Hãy thử lại sau.",
              }
            : message,
        ),
      );
    } finally {
      if (abortRef.current === controller) {
        setSending(false);
        abortRef.current = null;
      }
    }
  }

  function clearConversation() {
    abortRef.current?.abort();
    abortRef.current = null;
    setSending(false);
    setMessages([WELCOME_MESSAGE]);
    setDraft("");
  }

  return (
    <div className={open ? "chat-widget is-open" : "chat-widget"}>
      {open && (
        <section
          className="chat-panel"
          aria-label="Trợ lý tư vấn bất động sản"
        >
          <header className="chat-header">
            <div className="chat-agent-mark" aria-hidden="true">
              <Bot />
            </div>
            <div>
              <strong>Trợ lý Nhà Việt</strong>
              <span><i /> Tư vấn bất động sản</span>
            </div>
            <button
              type="button"
              className="chat-header-action"
              onClick={clearConversation}
              aria-label="Xóa lịch sử trò chuyện"
              title="Xóa lịch sử"
            >
              <Trash2 />
            </button>
            <button
              type="button"
              className="chat-header-action"
              onClick={() => setOpen(false)}
              aria-label="Đóng chatbot"
            >
              <X />
            </button>
          </header>

          <div className="chat-messages" aria-live="polite">
            {messages.map((message) => (
              <div
                className={`chat-message ${message.role}${message.isError ? " error" : ""}`}
                key={message.id}
              >
                {message.role === "assistant" && (
                  <span className="chat-message-icon" aria-hidden="true">
                    <Bot />
                  </span>
                )}
                <p>
                  {message.content || (
                    <span className="chat-typing" aria-label="Đang soạn câu trả lời">
                      <i /><i /><i />
                    </span>
                  )}
                </p>
              </div>
            ))}
            <div ref={endRef} />
          </div>

          <form
            className="chat-composer"
            onSubmit={(event) => {
              event.preventDefault();
              void sendMessage();
            }}
          >
            <label className="sr-only" htmlFor="chat-question">
              Câu hỏi dành cho trợ lý bất động sản
            </label>
            <textarea
              id="chat-question"
              ref={inputRef}
              rows={1}
              value={draft}
              maxLength={1000}
              placeholder="Ví dụ: Tìm căn hộ dưới 3 tỷ ở Quận 7"
              onChange={(event) => setDraft(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter" && !event.shiftKey) {
                  event.preventDefault();
                  void sendMessage();
                }
              }}
            />
            <button
              type="submit"
              disabled={!draft.trim() || sending}
              aria-label={sending ? "Đang gửi câu hỏi" : "Gửi câu hỏi"}
            >
              {sending ? <LoaderCircle className="spin" /> : <Send />}
            </button>
          </form>
          <small className="chat-disclaimer">
            Thông tin chỉ mang tính tham khảo. Hãy xác minh trước khi giao dịch.
          </small>
        </section>
      )}

      <button
        type="button"
        className="chat-launcher"
        onClick={() => setOpen((current) => !current)}
        aria-expanded={open}
        aria-label={open ? "Đóng trợ lý tư vấn" : "Mở trợ lý tư vấn bất động sản"}
      >
        {open ? <X /> : <MessageCircle />}
      </button>
    </div>
  );
}
