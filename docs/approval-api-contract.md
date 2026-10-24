# Contract đăng tin và xét duyệt

Trạng thái: FINAL v1.1 — đã đối chiếu hai khảo sát và mã nguồn ngày 23/10/2026. v1.1 bổ sung endpoint danh mục đọc để UI chọn tên hợp lệ thay vì nhập khóa DB.
Run Orca: `run_55b7db3023ae`. Manager: `graduation-thesis`.
Chia sẻ: worker đọc trực tiếp file tuyệt đối `D:/RealEstateMobile-Project/docs/approval-api-contract.md`; file trong worktree không tự đồng bộ.

## Hiện trạng đã xác minh

Spring Boot 4.1 / Java 21 / JPA; local MySQL, profile prod PostgreSQL; `ddl-auto=none`. Migration cần script đúng dialect, không áp dụng live trong task.
Enum `StatusProperty` dùng giá trị chuỗi tiếng Việt trong DB và JSON:

| Nghiệp vụ | Enum Java | Giá trị DB/API |
|---|---|---|
| Chờ duyệt | PENDING | Chờ duyệt |
| Được duyệt, công khai | PUBLISHED | Đang mở bán |
| Bị từ chối | REJECTED | Từ chối |
| Đã xóa | DELETED | Đã xóa |

Không đổi enum hay giá trị hiện có. Không thêm quy trình gửi duyệt lại.

## Endpoint giữ nguyên

- `GET /api/properties?page=1&limit=6`: công khai, chỉ `Đang mở bán`; trả `{message:"Success",data:{content:PropertyDTO[],currentPage,totalItems,totalPages}}`.
- `GET /api/secure/properties`: bearer JWT, chỉ tin của principal; `{message:"Success",data:PropertyDTO[]}`.
- Bổ sung có lý do: `GET /api/secure/property-options`, bearer JWT, chỉ đọc, tái sử dụng service danh mục/phường hiện có vì chưa có API tương đương. Trả `{message:"Success",data:{types:[{id,name}],categories:[{id,name}],wards:[{id,name,districtName}]}}`. UI chọn nhãn, gửi id; không lộ thông tin user. Endpoint này không tạo workflow duyệt mới.
- `POST /api/secure/properties`: bearer JWT, multipart, tạo/cập nhật theo `id`; title, address, price>0, area>0, legal, typeId, categoryId, wardId, description, files và các trường DTO hiện có. Chủ tin lấy từ principal, không tin userId/email/status/reviewer client. Trả DTO đã lưu gồm id và status thật.
- `GET /api/secure/properties/{id}`: bearer JWT; công khai nếu published, dữ liệu không công khai chỉ chủ tin hoặc Staff có quyền trên tin (và Admin theo quyền hiện có). Không để người dùng bất kỳ xem tin chờ/từ chối.
- `GET /admin/properties-list`: session Staff/Admin, giữ phân trang `page,size` và filter hiện có, Staff chỉ tin được phân công; filter `status=Chờ duyệt`.
- `GET /admin/properties-edit-{id}`: session Staff/Admin, giữ assignment authorization.
- `POST /admin/api/properties`: session + CSRF, JSON PropertyDTO hiện có. Khi xét duyệt, gửi dữ liệu form hiện có, `id`, `status` chính xác và `rejectionReason` khi từ chối. Giữ response envelope `{message,data,detail}`. Không thêm endpoint duyệt trùng.

## Hành vi mục tiêu đã chốt

- Tạo thành công luôn `Chờ duyệt`, chưa công khai; commit xong mới xử lý email tiếp nhận.
- Chỉ Staff hợp lệ (giữ quyền Admin đã có nếu được xác nhận) mới chuyển `Chờ duyệt` -> `Đang mở bán` hoặc `Từ chối`; Staff phải được phân công. Chặn cập nhật trực tiếp status qua luồng người đăng.
- Từ chối yêu cầu `rejectionReason.trim()` dài 1..1000 ký tự, lưu lý do và định danh/thời điểm người xét duyệt. Trả trường lý do cho chủ tin và reviewer có quyền; không phát tán qua danh sách công khai.
- Lặp cùng quyết định không tạo email mới; quyết định xung đột hoặc transition không hợp lệ trả 409. Backend bảo vệ concurrency.
- Lỗi validation mới: 422 `{message,detail:"VALIDATION_ERROR",data:{rejectionReason:"..."}}`; 401 chưa đăng nhập, 403 không đủ quyền, 404 không tồn tại/không được xem, 409 xung đột. Form validation cũ có thể giữ 400/list để tương thích, frontend xử lý cả hai.
- UI chỉ thay trạng thái sau response thành công rồi refetch. Sau tạo mới hiển thị đúng thông điệp tiếp nhận trong FRONTEND_RULES, không khẳng định mail đã được giao.
- Email lấy người nhận từ account chủ tin, ba mẫu theo BACKEND_RULES. Fake mailer trong tests; không SMTP thật. Outbox/dispatch sau commit, key sự kiện duy nhất, retry có giới hạn/backoff; lỗi email không rollback bài đăng.
- Khảo sát xác nhận không có resubmit chuyên biệt. Owner sửa nội dung giữ nguyên trạng thái, lý do và audit đã lưu; không reset về pending, không thêm nút gửi duyệt lại. Khi cần đổi chính sách chỉnh sửa tin đã duyệt phải có task riêng.

## Quyết định bổ sung và tương thích

- Giữ quyền quản trị ADMIN hiện có; Staff chỉ xét duyệt tin được phân công. Không mở rộng Staff ra mọi tin. Backend kiểm tra ở mutation, không chỉ GET form.
- Lặp cùng quyết định trả 200, không sửa lý do/reviewer/thời điểm duyệt và không tạo event mới. Payload nội dung y hệt không làm thay đổi dữ liệu. Endpoint generic vẫn cho lưu chỉnh sửa nội dung hợp lệ theo quyền hiện có khi status giữ nguyên; đây không phải transition và không tạo email quyết định mới. Không được âm thầm bỏ qua sửa nội dung của form admin chỉ vì status đang là published/rejected. Quyết định khác sau khi đã xử lý trả 409. Khóa/CAS tại DB bảo vệ các yêu cầu đồng thời.
- Manager chấp thuận trong phạm vi tính năng các thay đổi schema bổ sung cần thiết: cột nullable `rejection_reason`, `reviewed_by`, `reviewed_at`, bảng outbox có unique event key. Backend phải cung cấp SQL forward/rollback, phân tích thứ tự deploy, kiểm tra trên DB test; không tự chạy lên DB thật. Không đổi tên trạng thái hoặc cột hiện có. Metadata JSON bổ sung: `rejectionReason`, `reviewedBy`, `reviewedAt`; `createdDate` giữ định dạng Date ISO do Jackson hiện có (frontend parse ISO hoặc epoch để tương thích).
- Không có API danh mục sẵn có. v1.1 bổ sung endpoint chỉ đọc ở trên, tái sử dụng service hiện có cho web/mobile chọn danh mục/phường bằng tên; không yêu cầu người dùng nhập ID nội bộ hoặc tự đoán label -> ID. Backend vẫn xác minh các FK khi lưu.
- `wardId` có thể vắng trong request chỉ khi bộ phân tích địa chỉ hiện có xác định được phường hợp lệ. Sau parse, nếu FK type/category/ward thiếu hoặc không tồn tại, trả 422 với lỗi field có cấu trúc, không lưu/email. UI cho chọn phường hợp lệ để có thể đăng tin khi parser ngoài không khả dụng. Không gọi parser/provider thật trong automated tests.
- Favorites và detail không được làm lộ tin pending/rejected/deleted cho tài khoản khác; reason/audit chỉ owner/reviewer có quyền, loại khỏi public DTO. Giữ thông tin liên hệ công khai hiện có, không mở thêm PII.
- Worker không được tuyên bố SMTP có đảm bảo exactly-once khi provider chưa hỗ trợ idempotency. Outbox phải chống xử lý trùng trong ứng dụng và ghi rõ giới hạn nếu provider đã nhận mail nhưng ACK bị mất. Fake mailer kiểm chứng event key và retry không phát sinh event mới.
- Frontend chống double submit; tạo mới giữ dữ liệu khi lỗi và không tự retry mutation mù. Backend bảo đảm một event tiếp nhận cho mỗi bài được tạo; nếu hỗ trợ idempotency tạo mới, phải báo và cập nhật contract trước khi FE tích hợp.

## Ownership và nghiệm thu

Backend sở hữu Java, migrations, cấu hình email an toàn và test backend; Frontend sở hữu React web, Flutter mobile, `src/main/resources/templates/property/` và JS giao diện liên quan. Không worker nào sửa worktree của worker khác.

Nghiệm thu: tạo -> chờ -> approve/reject; lý do bắt buộc hai lớp; owner và assignment auth; không lộ tin riêng; commit fail không gửi mail; fake mail đúng account/nội dung; duplicate/concurrent không tạo event trùng; provider fail giữ trạng thái và retry; unit/integration/lint/build phù hợp. Manager review từng commit trước tích hợp trên nhánh riêng, không merge main/production.
