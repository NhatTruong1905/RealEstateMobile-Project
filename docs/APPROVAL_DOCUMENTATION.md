# Tài liệu đăng tin và xét duyệt

Bộ tài liệu được hợp nhất vào `graduation-thesis` ngày 24/10/2026. Commit này chỉ chứa tài liệu; mã tính năng, migration và test vẫn nằm trên các nhánh worker và nhánh `manager/approval-qa-20261023`. Không áp dụng kết quả test của nhánh QA cho mã hiện có trên `graduation-thesis`.

## Tài liệu chính

- [Báo cáo Manager sau tích hợp QA](approval-manager-report.md): kết quả cuối được trực tiếp kiểm chứng và các giới hạn.
- [API contract FINAL v1.1](approval-api-contract.md): contract mục tiêu của bản triển khai trên nhánh QA.
- [Bàn giao Backend, gồm bản sửa R-07](backend-approval-implementation-report.md): API, phân quyền, migration, outbox, cấu hình và cách chạy test.
- [Bàn giao Frontend](frontend-approval-implementation-report.md): React, Flutter, Staff Thymeleaf và blocker APK.
- [Task board](approval-task-board.md): có checkpoint lịch sử; mục “Kết quả cuối sau kiểm chứng QA” thay thế các trạng thái cũ phía trên.
- [Kế hoạch QA và finding](approval-qa-plan.md): kế hoạch và các mốc review; kết luận đóng lỗi xem báo cáo Manager.

## Khảo sát lịch sử

- [Khảo sát Backend trước triển khai](backend-approval-survey.md).
- [Khảo sát Frontend trước triển khai](frontend-approval-survey.md), lấy từ file local chưa commit trong worktree Frontend; không thay đổi worktree đó.

Các mô tả thiếu chức năng, DRAFT, chưa chạy test hoặc đang chờ giao việc trong khảo sát phản ánh thời điểm khảo sát, không phải trạng thái bản QA cuối. Đường dẫn tuyệt đối trong báo cáo là vị trí trên máy thực hiện; các commit được ghi để truy vết mã nguồn.

## Kết quả được ghi nhận

Trên nhánh QA: Backend226 lượt test và WAR đạt; web/Staff27 test, lint/build đạt; Flutter9 test đạt, analyzer0 error/warning và122info như baseline. APK chưa build thành công do tải dependency/DNS; chưa kiểm browser/device E2E, DB native hoặc SMTP thật. Không chấp thuận toàn bộ release chỉ từ bộ tài liệu này.

Không đưa AGENTS.md, docs/agent-rules, log, artifact build hoặc cấu hình bí mật vào commit tài liệu. Chưa push remote hay merge mã nguồn vào main/production.
