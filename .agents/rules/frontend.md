---
trigger: always_on
description: "Quy tắc áp dụng khi thiết kế hoặc chỉnh sửa giao diện frontend web/mobile."
---

# Quy tắc thiết kế frontend

Áp dụng khi thiết kế hoặc chỉnh sửa giao diện frontend web/mobile.

- Không tự tạo thư mục test và không tự viết thêm unit test, trừ khi người dùng yêu cầu rõ ràng.
- Kiểm tra thay đổi bằng build, lint và kiểm tra trực quan hoặc thao tác thực tế khi công cụ hỗ trợ.
- Không tự xóa hoặc sửa các test hiện có chỉ để áp dụng quy tắc này.

## Bàn giao từ web sang mobile

- Trước khi kết thúc một lượt có thay đổi frontend web, cập nhật [bàn giao nghiệp vụ web sang mobile](../../docs/WEB_TO_MOBILE_HANDOFF.md). Ghi cả thay đổi backend trong cùng lượt nếu ảnh hưởng đến cách web hoặc mobile thực hiện nghiệp vụ.
- Ghi theo nghiệp vụ đã thay đổi, gồm ngày, màn hình hoặc luồng web, hành vi mới, quyền và trạng thái, hợp đồng API hoặc dữ liệu nếu có, các tệp liên quan, việc cần làm ở Flutter và kết quả kiểm tra. Với chỉnh sửa chỉ về bố cục hoặc trình bày, ghi ngắn gọn tác động và cho biết mobile có cần áp dụng hay không.
- Cập nhật mục đã có nếu cùng nghiệp vụ. Có thể liên kết đến tài liệu chuyên biệt để tránh ghi trùng. Đánh dấu rõ phần đã làm, phần còn chờ và phần chưa kiểm tra; chỉ ghi nhận là đã triển khai khi có thay đổi trong mã.
- Khi làm mobile, đọc tài liệu bàn giao và mục liên quan, đối chiếu với API và mã đang dùng, rồi cập nhật tình trạng mobile sau khi đã thực hiện và kiểm tra.
