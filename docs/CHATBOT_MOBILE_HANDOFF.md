# Bàn giao tích hợp chatbot cho Flutter

Cập nhật ngày 24/11/2026. Phần mobile chưa chuyển sang hợp đồng mới. `RagChatService.dart` và `RagChatModal.dart` vẫn sử dụng API cũ. Bộ lọc và thay đổi truy xuất phía máy chủ được dùng chung ngay khi AI service được triển khai.

## Hợp đồng để đồng bộ với web

Gửi `POST /api/chat-rag/v2/stream` tới AI service, với `Accept: text/event-stream` và body JSON:

```json
{
  "question": "Cho tôi biết thêm về tin thứ 2",
  "history": [
    {
      "role": "assistant",
      "content": "Tôi tìm thấy hai tin phù hợp.",
      "property_ids": ["101", "102"]
    }
  ]
}
```

- `question` tối đa 4.000 ký tự. Gửi tối đa 15 tin lịch sử đã hoàn tất, mỗi tin tối đa 12.000 ký tự, role là `user` hoặc `assistant`.
- `property_ids` tùy chọn. Với tin assistant, lấy ID theo thứ tự thẻ tin thực tế đã hiển thị. Ví dụ trên tham chiếu ID `102`. AI kiểm tra lại trạng thái công khai và phiên bản dữ liệu. Người dùng cũng có thể nhập `mã tin 102`.
- Flutter có thể tiếp tục dùng `http.Client.send`. Giải mã UTF-8 liên tục qua các chunk và tách frame SSE bằng dòng trống. Một frame có thể trải qua nhiều chunk.

| Event | Payload | Xử lý trên mobile |
|---|---|---|
| `delta` | `{"text":"…"}` | Nối vào phần trả lời đang hiển thị. |
| `properties` | `{"items":[…]}` | Giữ tạm danh sách thẻ, gồm `property_id`, `title`, `price_vnd`, `area_m2`, `district`, `ward`, `type` dưới dạng chuỗi. |
| `done` | `{}` | Xác nhận hoàn tất. Lưu câu trả lời và danh sách thẻ; điều hướng bằng `property_id`. |
| `error` | `{"code":"unavailable","message":"…"}` | Hiển thị lỗi riêng. Loại câu trả lời dở và thẻ tạm khỏi lịch sử gửi API. |

## Các việc khi quay lại mobile

1. Chuyển URL của `RagChatService` sang v2. Phân biệt HTTP 400/422, 401, 429, timeout, event `error` và EOF trước `done`. Với 429 có thể dùng `Retry-After`. Không tự phát lại một request đã bắt đầu stream.
2. Thêm nút **Dừng trả lời**, hủy request đang chạy khi xóa cuộc hội thoại hoặc đổi tài khoản. Chỉ lưu tin hợp lệ sau `done`. Tách dữ liệu theo tài khoản hoặc xóa khi đăng xuất vì key `rag_chat_history_v1` hiện dùng chung trên thiết bị.
3. Dùng metadata của event `properties` để dựng thẻ. Tái sử dụng màn chi tiết đã có, giữ các kiểm tra quyền ở màn đó. Gửi lại thứ tự ID của thẻ nếu muốn hỗ trợ câu nối tiếp như *tin thứ 2*.
4. Kiểm tra riêng thành công, không có kết quả, đổi thuê/mua và ngân sách, tin vừa ẩn, stream ngắt, dừng, xóa lịch sử và đổi tài khoản. Thử cả thiết bị/emulator lẫn URL triển khai thực tế.
5. Nếu bật `CHAT_GATEWAY_TOKEN` ở FastAPI, mobile cũng phải đi qua gateway được phép chuyển tiếp. Không đưa token nội bộ vào APK. App có thể tiếp tục gọi `POST /api/chat-rag` và `POST /api/chat-rag/stream` trong giai đoạn chuyển đổi khi routing và quyền truy cập còn tương thích.

Tham khảo [báo cáo triển khai và benchmark web](CHATBOT_WEB_IMPROVEMENTS.md) và [client web](../real_estate_frontend-web/src/services/api/chat/chatApi.ts).
