"""Pure listing eligibility filters and greeting detection; no provider calls."""
import re
import hashlib

def is_pure_greeting(question: str) -> bool:
    q_clean = re.sub(r"[^\w\s]", "", question.lower().strip())
    greeting_words = {"chào", "xin chào", "chào bạn", "chào em", "chào anh", "chào chị", "hi", "hello", "hey",
                      "chào shop", "chào ad", "chào admin"}
    words = q_clean.split()

    re_keywords = ["mua", "thuê", "bán", "giá", "tỷ", "triệu", "phòng", "căn hộ", "nhà", "quận", "đất", "dự án",
                   "biệt thự", "pháp lý"]

    has_re_intent = any(kw in q_clean for kw in re_keywords)
    if not has_re_intent:
        if q_clean in greeting_words or any(w in greeting_words for w in words):
            return True
    return False


def extract_budget(question: str) -> float:
    q_lower = question.lower()

    ty_match = re.search(r"(\d+(?:[.,]\d+)?)\s*tỷ", q_lower)
    if ty_match:
        val_str = ty_match.group(1).replace(",", ".")
        return float(val_str) * 1_000_000_000

    trieu_match = re.search(r"(\d+(?:[.,]\d+)?)\s*triệu", q_lower)
    if trieu_match:
        val_str = trieu_match.group(1).replace(",", ".")
        return float(val_str) * 1_000_000

    raw_vnd_match = re.search(r"(\d[\d.,]*)\s*(?:vnđ|đ|dong)", q_lower)
    if raw_vnd_match:
        val_str = raw_vnd_match.group(1).replace(".", "").replace(",", "")
        try:
            val = float(val_str)
            if val >= 100_000:
                return val
        except ValueError:
            pass

    return None


def extract_price(content: str) -> float:
    content_lower = content.lower()

    price_match = re.search(r"(?:mức giá|giá):\s*([^\n]+)", content_lower)
    if not price_match:
        return None

    price_str = price_match.group(1)

    ty_match = re.search(r"(\d+(?:[.,]\d+)?)\s*tỷ", price_str)
    if ty_match:
        val_str = ty_match.group(1).replace(",", ".")
        return float(val_str) * 1_000_000_000

    trieu_match = re.search(r"(\d+(?:[.,]\d+)?)\s*triệu", price_str)
    if trieu_match:
        val_str = trieu_match.group(1).replace(",", ".")
        return float(val_str) * 1_000_000

    raw_match = re.search(r"(\d[\d.,]*)", price_str)
    if raw_match:
        raw_str = raw_match.group(1).replace(".", "").replace(",", "")
        try:
            return float(raw_str)
        except ValueError:
            pass

    return None


def filter_documents(docs, search_query):
    q_lower = search_query.lower()
    budget = extract_budget(search_query)

    is_buy = any(kw in q_lower for kw in ["mua", "sang nhượng", "cần mua", "tìm mua", "bán", "muốn"])
    is_rent = any(kw in q_lower for kw in ["cho thuê", "tìm thuê", "cần thuê"]) or ("thuê" in q_lower and not is_buy)

    if budget is not None:
        if budget >= 100_000_000:
            is_buy = True
            is_rent = False
        else:
            is_rent = True
            is_buy = False

    seen_ids = set()
    filtered_docs = []

    for doc in docs:
        content = doc.page_content
        content_lower = content.lower()

        prop_id_match = re.search(r"property id\s*(\d+)", content_lower)
        if prop_id_match:
            pid = prop_id_match.group(1)
            if pid in seen_ids:
                continue


        if is_buy:
            if "cho thuê" in content_lower and "bán" not in content_lower:
                continue
        elif is_rent:
            if "bán" in content_lower and "cho thuê" not in content_lower and "thuê" not in content_lower:
                continue

        if budget is not None:
            doc_price = extract_price(content_lower)
            if doc_price is not None and doc_price > budget:
                continue

        identity = prop_id_match.group(1) if prop_id_match else (doc.metadata.get("source_id") or hashlib.sha256(content.encode()).hexdigest())
        if identity in seen_ids:
            continue
        seen_ids.add(identity)
        filtered_docs.append(doc)

    return filtered_docs


def format_docs_with_greeting_check(inputs: dict) -> str:
    question = inputs.get("question", "")
    if is_pure_greeting(question):
        return "CHỈ_CHÀO_HỎI_KHÔNG_CÓ_NHU_CẦU_BĐS"
    docs = filter_documents(inputs.get("docs", []), inputs.get("search_query", question))
    if not docs:
        return "KHÔNG_CÓ_BĐS_PHÙ_HỢP_VỚI_NGÂN_SÁCH"
    return "\n\n".join(doc.page_content for doc in docs)
