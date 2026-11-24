from typing import Annotated, List, Literal, Optional
from pydantic import BaseModel, Field


class MessageItem(BaseModel):
    role: Literal["user", "assistant"] = Field(..., example="user")
    content: str = Field(..., max_length=12000, example="Tôi muốn tìm nhà Quận 1")
    property_ids: list[Annotated[str, Field(pattern=r"^[1-9][0-9]{0,9}$")]] = Field(
        default_factory=list, max_length=20,
    )


class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=4000, example="Chào bạn?")
    history: Optional[List[MessageItem]] = Field(default=None, max_length=15, description="Lịch sử trò chuyện trước đó")


class ChatResponse(BaseModel):
    answer: str


class RealEstateIntentSummary(BaseModel):
    transaction_type: Optional[str] = Field(
        default=None,
        description="Loại giao dịch: 'bán' hoặc 'cho thuê'."
    )
    property_type: Optional[str] = Field(
        default=None,
        description="Danh mục / Loại BĐS (Ví dụ: 'căn hộ', 'chung cư', 'biệt thự', 'nhà phố')."
    )
    location: Optional[str] = Field(
        default=None,
        description="Vị trí, Quận Huyện, Phường, Đường hoặc Tên dự án BĐS (Ví dụ: 'Thảo Điền', 'Thành phố Thủ Đức', 'Masteri Thảo Điền')."
    )
    budget_vnd: Optional[float] = Field(
        default=None,
        description="Mức ngân sách tối đa tính bằng VNĐ (Ví dụ: 4.5 tỷ -> 4500000000)."
    )
    bedrooms: Optional[int] = Field(
        default=None,
        description="Số phòng ngủ yêu cầu (Ví dụ: 2)."
    )
    bathrooms: Optional[int] = Field(
        default=None,
        description="Số phòng vệ sinh / WC yêu cầu (Ví dụ: 2)."
    )
    direction: Optional[str] = Field(
        default=None,
        description="Hướng nhà / Hướng ban công (Ví dụ: 'Đông Nam', 'Tây Bắc')."
    )
    legal: Optional[str] = Field(
        default=None,
        description="Tình trạng pháp lý (Ví dụ: 'sổ hồng', 'sổ hồng riêng', 'hợp đồng mua bán')."
    )
    special_requirements: List[str] = Field(
        default_factory=list,
        description="Danh sách đặc điểm, tiện ích bổ sung (Ví dụ: ['view sông', 'ban công', 'thiết kế hiện đại'])."
    )
