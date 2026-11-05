"""Bounded conversation history and structured search-intent preparation."""
import logging
from api.schemas import RealEstateIntentSummary

log = logging.getLogger(__name__)

def format_history_text(history: list) -> str:
    if not history:
        return "Không có lịch sử hội thoại trước đó."
    formatted = []
    for item in history:
        if hasattr(item, "role"):
            role = item.role
            content = item.content
        elif isinstance(item, dict):
            role = item.get("role", "user")
            content = item.get("content", "")
        else:
            continue
        role_label = "Khách hàng" if role == "user" else "Trợ lý AI"
        if content and content.strip():
            formatted.append(f"{role_label}: {content.strip()}")
    if not formatted:
        return "Không có lịch sử hội thoại trước đó."
    return "\n".join(formatted)


def sanitize_and_budget_history(history: list, max_assistant_chars: int = 150, max_total_chars: int = 1200) -> list:
    if not history:
        return []

    cleaned_items = []
    for item in history:
        role = item.role if hasattr(item, "role") else item.get("role", "user")
        content = item.content if hasattr(item, "content") else item.get("content", "")
        content = content.strip()

        if role == "assistant" and len(content) > max_assistant_chars:
            content = content[:max_assistant_chars] + "... [đã ẩn chi tiết BĐS]"

        cleaned_items.append({"role": role, "content": content[:max_total_chars]})

    selected = []
    current_chars = 0
    for item in reversed(cleaned_items):
        item_len = len(item["content"])
        if current_chars + item_len > max_total_chars and selected:
            break
        selected.append(item)
        current_chars += item_len

    return list(reversed(selected))


def extract_user_queries_only(history: list) -> list:
    user_queries = []
    for item in history:
        role = item.role if hasattr(item, "role") else item.get("role", "")
        content = item.content if hasattr(item, "content") else item.get("content", "")
        if role == "user" and content and content.strip():
            user_queries.append(content.strip())
    return user_queries


class ConversationManager:
    def __init__(self, summary_chain):
        self.summary_chain = summary_chain

    def _extract_intent_from_history(self, history_list: list) -> RealEstateIntentSummary:
        if not history_list:
            return RealEstateIntentSummary()

        formatted_raw = format_history_text(history_list)
        summary_prompt = f"""Đọc đoạn chat dưới đây và trích xuất các tiêu chí BĐS mà khách hàng tìm kiếm:
        - CHỈ lấy thông tin có trong đoạn chat.
        - Nếu khách đổi ý (vd từ Q1 sang Q7), CHỈ LẤY TIÊU CHÍ MỚI NHẤT.
        
        Lịch sử trò chuyện:
        {formatted_raw}
        """

        try:
            intent: RealEstateIntentSummary = self.summary_chain.invoke(summary_prompt)
            return intent
        except Exception as e:
            log.warning("intent status=failed reason=%s", type(e).__name__)
            return RealEstateIntentSummary()


    def _prepare_inputs(self, question: str, history: list = None) -> dict:
        question = question[:4000]
        history_list = history or []

        budgeted_history = sanitize_and_budget_history(history_list, max_assistant_chars=150, max_total_chars=1200)

        if len(budgeted_history) <= 4:
            history_str = format_history_text(budgeted_history)

            user_queries = extract_user_queries_only(budgeted_history)
            search_query = " ".join(user_queries + [question.strip()]) if user_queries else question.strip()

        else:
            older_history = budgeted_history[:-2] # Lấy từ đầu danh sách(vị trí 0) đến trước 2 phần tử cuối cùng (Lấy đầu bỏ 2 cuối)
            recent_history = budgeted_history[-2:] # Lấy tới vị trí thứ 2 từ dưới đếm lên (Lấy 2 cuối bỏ đầu)

            intent = self._extract_intent_from_history(older_history)

            query_parts = []
            if intent.transaction_type:
                query_parts.append(f"Cần {intent.transaction_type}")
            if intent.property_type:
                query_parts.append(f"loại {intent.property_type}")
            if intent.location:
                query_parts.append(f"tại {intent.location}")
            if intent.budget_vnd:
                query_parts.append(f"giá {int(intent.budget_vnd)} VNĐ")
            if intent.bedrooms:
                query_parts.append(f"{intent.bedrooms} phòng ngủ")
            if intent.bathrooms:
                query_parts.append(f"{intent.bathrooms} phòng vệ sinh")
            if intent.direction:
                query_parts.append(f"hướng {intent.direction}")
            if intent.legal:
                query_parts.append(f"pháp lý {intent.legal}")
            if intent.special_requirements:
                query_parts.append(" ".join(intent.special_requirements))

            recent_user_queries = extract_user_queries_only(recent_history)
            query_parts.extend(recent_user_queries)
            query_parts.append(question.strip())

            search_query = " ".join(query_parts)

            recent_history_str = format_history_text(recent_history)
            summary_parts = []
            if intent.transaction_type: summary_parts.append(f"Giao dịch: {intent.transaction_type}")
            if intent.property_type: summary_parts.append(f"Loại: {intent.property_type}")
            if intent.location: summary_parts.append(f"Vị trí: {intent.location}")
            if intent.budget_vnd: summary_parts.append(f"Ngân sách: <= {int(intent.budget_vnd)} VNĐ")
            if intent.bedrooms: summary_parts.append(f"{intent.bedrooms}PN")
            if intent.bathrooms: summary_parts.append(f"{intent.bathrooms}WC")
            if intent.direction: summary_parts.append(f"Hướng: {intent.direction}")
            if intent.legal: summary_parts.append(f"Pháp lý: {intent.legal}")
            if intent.special_requirements: summary_parts.append(
                f"Yêu cầu khác: {', '.join(intent.special_requirements)}")

            summary_label = " | ".join(summary_parts) if summary_parts else "Chưa rõ tiêu chí"
            history_str = f"[Tiêu chí BĐS tổng hợp từ lịch sử cũ: {summary_label}]\n\n{recent_history_str}"

        return {
            "question": question.strip(),
            "search_query": search_query,
            "history_str": history_str,
        }
