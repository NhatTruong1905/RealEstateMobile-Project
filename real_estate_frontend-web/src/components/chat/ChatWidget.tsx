import { useEffect, useRef, useState } from "react";
import { Bot, MessageCircle, Send, Square, Trash2, X } from "lucide-react";
import { Link } from "react-router-dom";
import { chatApi, type ChatHistoryItem, type ChatProperty } from "../../services/api/chat/chatApi";

interface ChatMessage extends ChatHistoryItem {
  id: string;
  isError?: boolean;
  pending?: boolean;
  properties?: ChatProperty[];
}

const STORAGE_KEY = "real-estate-web-chat-history";
const WELCOME_MESSAGE: ChatMessage = {
  id: "welcome",
  role: "assistant",
  content:
    "Chào bạn, tôi là trợ lý Nhà Thật. Bạn đang tìm mua hay thuê bất động sản ở khu vực nào?",
};

function loadHistory(): ChatMessage[] {
  try {
    const stored = JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]");
    if (Array.isArray(stored)) {
      const complete = stored
        .filter((message) => message && !message.pending)
        .map((message) => message.id === WELCOME_MESSAGE.id ? WELCOME_MESSAGE : message);
      if (complete.length) return complete;
    }
    return [WELCOME_MESSAGE];
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
      localStorage.setItem(STORAGE_KEY, JSON.stringify(
        messages.filter((message) => !message.pending).slice(-30),
      ));
    }
    endRef.current?.scrollIntoView({ behavior: window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth" });
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
    if (!question || abortRef.current) return;

    const userMessage: ChatMessage = {
      id: `user-${Date.now()}`,
      role: "user",
      content: question,
    };
    const assistantId = `assistant-${Date.now()}`;
    const history = messages
      .filter((message) => message.id !== "welcome" && !message.isError)
      .map(({ role, content, properties }) => ({
        role,
        content,
        property_ids: properties?.map((property) => property.property_id),
      }));

    setDraft("");
    setSending(true);
    setMessages((current) => [
      ...current,
      userMessage,
      { id: assistantId, role: "assistant", content: "", pending: true },
    ]);

    const controller = new AbortController();
    abortRef.current = controller;
    try {
      const properties = await chatApi.streamAnswer(
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
      if (!controller.signal.aborted) {
        setMessages((current) => current.map((message) =>
          message.id === assistantId ? { ...message, properties, pending: false } : message,
        ));
      }
    } catch (error) {
      if (controller.signal.aborted) return;
      setMessages((current) =>
        current.map((message) =>
          message.id === assistantId
            ? {
                ...message,
                isError: true,
                pending: false,
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

  function stopAnswer() {
    abortRef.current?.abort();
    abortRef.current = null;
    setSending(false);
    setMessages((current) => current.map((message) => message.pending
      ? { ...message, pending: false, isError: true, content: "Đã dừng câu trả lời." }
      : message));
    inputRef.current?.focus();
  }

  return (
    <div className={open ? "chat-widget is-open" : "chat-widget"}>
        <section
          className="chat-panel"
          hidden={!open}
          inert={!open}
          aria-hidden={!open}
          aria-label="Trợ lý tư vấn bất động sản"
        >
          <header className="chat-header">
            <div className="chat-agent-mark" aria-hidden="true">
              <Bot />
            </div>
            <div>
              <strong>Trợ lý Nhà Thật</strong>
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

          <div className="chat-messages" aria-live="polite" aria-busy={sending}>
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
                <div className="chat-message-body">
                <p role={message.isError ? "alert" : undefined}>
                  {message.content || (
                    <span className="chat-typing" aria-label="Đang soạn câu trả lời">
                      <i /><i /><i />
                    </span>
                  )}
                </p>
                {!!message.properties?.length && (
                  <ul className="chat-property-list" aria-label="Tin bất động sản">
                    {message.properties.map((property) => (
                      <li key={property.property_id}>
                        <Link to={`/properties/${property.property_id}`} onClick={() => setOpen(false)}>
                          <strong>{property.title || `Tin #${property.property_id}`}</strong>
                          <span>{[property.ward, property.district, property.type].filter(Boolean).join(" · ")}</span>
                          <span>
                            {/^[0-9]+(?:\.[0-9]+)?$/.test(property.price_vnd) &&
                              new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(Number(property.price_vnd))}
                            {property.area_m2 && (
                              <> {property.price_vnd && "· "}{property.area_m2} m²</>
                            )}
                          </span>
                        </Link>
                      </li>
                    ))}
                  </ul>
                )}
                </div>
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
              placeholder="Ví dụ: Căn hộ dưới 3 tỷ"
              onChange={(event) => setDraft(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter" && !event.shiftKey && !event.nativeEvent.isComposing) {
                  event.preventDefault();
                  void sendMessage();
                }
              }}
            />
            {sending ? (
              <button type="button" aria-label="Dừng trả lời" onClick={stopAnswer}><Square /></button>
            ) : (
              <button type="submit" disabled={!draft.trim()} aria-label="Gửi câu hỏi"><Send /></button>
            )}
          </form>
          <small className="chat-disclaimer">
            Thông tin chỉ mang tính tham khảo. Hãy xác minh trước khi giao dịch.
          </small>
        </section>

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
