import re

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
