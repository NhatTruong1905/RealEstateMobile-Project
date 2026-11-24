import re
import unicodedata
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation


def normalize(text):
    decomposed = unicodedata.normalize("NFD", str(text).lower().replace("đ", "d"))
    plain = "".join(char for char in decomposed if not unicodedata.combining(char))
    return re.sub(r"\s+", " ", plain).strip()


NUMBER = r"\d+(?:[.,]\d+)?"
MONEY = re.compile(
    rf"(?P<amount>{NUMBER})\s*(?P<unit>ty|ti|trieu|tr)\b"
    rf"(?:\s*(?P<tail>{NUMBER})\s*(?:trieu|tr)\b)?"
    r"|(?P<vnd>\d[\d.,]*)\s*(?:vnd|dong|d)\b"
)
TRANSACTION = re.compile(r"\b(?:cho thue|thue|mua|ban|sang nhuong|rent|sale)\b")
QUERY_TRANSACTION = re.compile(r"\b(?:cho thue|thue|mua|bán|sang nhuong|rent|sale)\b")
DISTRICT = re.compile(
    r"\b(?:quan\s*|q\.?\s*)(\d{1,2})\b"
    r"|\b(thu duc|binh thanh|tan binh|tan phu|phu nhuan|go vap|binh tan|binh chanh|"
    r"hoc mon|cu chi|nha be|can gio)\b"
)
BEDROOMS = re.compile(r"\b(\d+)\s*(?:phong ngu|pn)\b")
AREA = re.compile(rf"\b({NUMBER})\s*m(?:2|²)\b")
LEGAL = re.compile(r"\b(?:so hong(?: rieng)?|so do|hop dong mua ban)\b")
REMOVE = re.compile(r"\b(?:bo qua|khong can|khong gioi han|bo tieu chi)\s*")
RESET = re.compile(r"^(?:bat dau lai|tim lai tu dau|xoa tieu chi)(?:[.!,:;\s]|$)")


def money(match):
    if match["vnd"]:
        return Decimal(re.sub(r"[.,]", "", match["vnd"]))
    value = Decimal(match["amount"].replace(",", "."))
    if match["unit"] in {"ty", "ti"}:
        return value * 1_000_000_000 + Decimal((match["tail"] or "0").replace(",", ".")) * 1_000_000
    return value * 1_000_000


def transaction(value):
    return "rent" if value in {"thue", "cho thue", "rent"} else "sale"


def district(value):
    matches = list(DISTRICT.finditer(value))
    if matches:
        last = matches[-1]
        return str(int(last[1])) if last[1] else last[2]
    return str(int(value)) if value.isdecimal() else value


def decimal_value(value):
    try:
        result = Decimal(str(value))
        return result if result.is_finite() and result >= 0 else None
    except (InvalidOperation, ValueError):
        return None


@dataclass
class SearchCriteria:
    transaction: str | None = None
    min_price: Decimal | None = None
    max_price: Decimal | None = None
    district: str | None = None
    bedrooms: int | None = None
    min_area: Decimal | None = None
    max_area: Decimal | None = None
    legal: str | None = None

    @classmethod
    def from_turns(cls, turns):
        criteria = cls()
        for turn in turns:
            query = normalize(turn)
            if RESET.match(query):
                criteria = cls()
            for removal in REMOVE.finditer(query):
                rest = query[removal.end():]
                for pattern, fields in (
                    (r"(?:ngan sach|gia)\b", ("min_price", "max_price")),
                    (r"(?:khu vuc|vi tri|quan)\b", ("district",)),
                    (r"(?:so phong|phong ngu)\b", ("bedrooms",)),
                    (r"dien tich\b", ("min_area", "max_area")),
                    (r"phap ly\b", ("legal",)),
                    (r"loai giao dich\b", ("transaction",)),
                ):
                    if re.match(pattern, rest):
                        for field in fields:
                            setattr(criteria, field, None)
            query = REMOVE.sub("", query)
            transaction_query = normalize(re.sub(r"\bbán\b", "qbanbds", turn, flags=re.IGNORECASE))
            transaction_query = LEGAL.sub("", transaction_query.replace("hop dong mua qbanbds", ""))
            for match in QUERY_TRANSACTION.finditer(transaction_query.replace("qbanbds", "bán")):
                kind = transaction(match[0])
                if criteria.transaction and criteria.transaction != kind:
                    criteria.min_price = criteria.max_price = None
                criteria.transaction = kind
            prices = list(MONEY.finditer(query))
            if prices:
                last = prices[-1]
                before = query[:last.start()]
                if len(prices) >= 2 and re.fullmatch(r"\s*(?:den|toi|-)\s*", query[prices[-2].end():last.start()]):
                    criteria.min_price, criteria.max_price = money(prices[-2]), money(last)
                elif re.search(r"\b(?:tu|tren|hon|toi thieu)\s*$", before):
                    criteria.min_price, criteria.max_price = money(last), None
                else:
                    criteria.min_price, criteria.max_price = None, money(last)
            if DISTRICT.search(query):
                criteria.district = district(query)
            for match in BEDROOMS.finditer(query):
                criteria.bedrooms = int(match[1])
            areas = list(AREA.finditer(query))
            if areas:
                match = areas[-1]
                value = Decimal(match[1].replace(",", "."))
                if len(areas) >= 2 and re.fullmatch(r"\s*(?:den|toi|-)\s*", query[areas[-2].end():match.start()]):
                    criteria.min_area, criteria.max_area = Decimal(areas[-2][1].replace(",", ".")), value
                elif re.search(r"\b(?:duoi|toi da|khong qua)\s*$", query[:match.start()]):
                    criteria.min_area, criteria.max_area = None, value
                else:
                    criteria.min_area, criteria.max_area = value, None
            for match in LEGAL.finditer(query):
                criteria.legal = match[0]
        return criteria

    def matches(self, metadata):
        if self.transaction:
            kind = TRANSACTION.search(normalize(metadata.get("type", "")))
            if not kind or transaction(kind[0]) != self.transaction:
                return False
        if self.district and district(normalize(metadata.get("district", ""))) != self.district:
            return False
        if self.bedrooms is not None and decimal_value(metadata.get("bedrooms")) != self.bedrooms:
            return False
        if self.legal and self.legal not in normalize(metadata.get("legal", "")):
            return False
        for key, lower, upper in (
            ("price_vnd", self.min_price, self.max_price),
            ("area_m2", self.min_area, self.max_area),
        ):
            if lower is not None or upper is not None:
                value = decimal_value(metadata.get(key))
                if value is None or (lower is not None and value < lower) or (upper is not None and value > upper):
                    return False
        return True
