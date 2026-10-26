# Cơ chế dọn ảnh với storage_cleanup_task

Tài liệu mô tả mã nguồn tại thời điểm 26/10/2026.

## Mục đích

`storage_cleanup_task` là bảng lưu công việc dọn file ảnh trên dịch vụ storage. Đây không phải bảng danh sách tất cả ảnh đang được sử dụng.

Database và storage không dùng chung một transaction. Một file có thể đã upload thành công nhưng việc lưu database lại thất bại. Bảng này giúp hệ thống ghi nhớ và thử dọn file không còn cần thiết, kể cả khi tiến trình bị gián đoạn.

## Khi cập nhật ảnh

- Ảnh vẫn được sử dụng thì giữ nguyên.
- Với ảnh cũ bị thay thế hoặc loại bỏ, khi luồng nghiệp vụ gọi `retire(url)`, hệ thống tạo task xóa trong transaction hiện tại. Sau khi database commit thành công, hệ thống thử xóa file ngay.
- Nếu transaction rollback, task loại bỏ ảnh cũ cũng rollback, nên ảnh cũ không bị xóa bởi task đó.
- Nếu xóa file lỗi, task được giữ lại để scheduler thử lại sau.

Vì vậy, không phải ảnh cũ luôn phải đợi một khoảng thời gian mới bị xóa. Điểm quyết định là **database đã commit thành công hay chưa**; code thử xóa ngay sau commit.

## Khi upload ảnh mới

1. Trước khi upload, `planUpload()` tạo task `PENDING` trong một transaction riêng, với thời điểm xử lý sau 1 giờ. Task này vẫn tồn tại nếu transaction nghiệp vụ thất bại.
2. Hệ thống upload file lên storage.
3. Nếu upload thành công, `completeUpload()` đánh dấu task là `RETAINED` trong transaction nghiệp vụ.
4. Khi transaction nghiệp vụ commit, hệ thống xử lý task `RETAINED`: xóa bản ghi task và giữ nguyên file ảnh.
5. Nếu transaction rollback, thay đổi `RETAINED` cũng rollback. Callback `rollbackUpload()` đặt lịch dọn ảnh sau khoảng 60 giây.
6. Nếu tiến trình bị dừng trước khi hoàn tất các bước trên, task dự phòng ban đầu có thể được xử lý khi đến hạn 1 giờ.

Mốc 60 giây và 1 giờ là thời điểm task đủ điều kiện xử lý, không bảo đảm file được xóa đúng giây đó. Việc xử lý còn phụ thuộc scheduler, trạng thái ứng dụng và khả năng truy cập storage.

## Các cột

| Cột | Ý nghĩa |
|---|---|
| `id` | ID công việc |
| `provider` | Nhà cung cấp storage chứa file |
| `object_key` | Khóa của file trong storage, dùng để xóa file |
| `url` | URL ảnh, đồng thời dùng để kiểm tra tham chiếu avatar |
| `state` | Trạng thái công việc |
| `attempts` | Số lần đã thử xóa file |
| `next_attempt_at` | Thời điểm sớm nhất được xử lý tiếp |
| `created_at` | Thời điểm tạo công việc |

## Các trạng thái

| Trạng thái | Cách xử lý |
|---|---|
| `PENDING` | Chờ xử lý dọn file khi đến hạn |
| `RETAINED` | Giữ file ảnh; khi xử lý chỉ xóa bản ghi task |
| `FAILED` | Đã thất bại sau 8 lần thử xóa; scheduler không tự chọn lại |

Xóa file thành công sẽ xóa luôn bản ghi task, nên bảng không có trạng thái `DONE` để lưu lịch sử hoàn thành.

## Scheduler và retry

- Scheduler chỉ hoạt động khi `storage.cleanup.enabled=true`. Cấu hình mặc định trong repo là bật, có thể được ghi đè bằng `STORAGE_CLEANUP_ENABLED`.
- Mặc định scheduler chạy với khoảng nghỉ 60 giây giữa các lượt, chọn tối đa 20 task đến hạn thuộc provider hiện tại.
- Khi xóa lỗi, thời gian chờ tăng dần: 60, 120, 240 giây…; công thức có giới hạn tối đa 1 ngày. Sau lần thất bại thứ 8, task chuyển sang `FAILED`.
- Trước khi xóa một task `PENDING`, code kiểm tra URL có đang được dùng làm avatar của người dùng hay không. Nếu có, hệ thống giữ file và xóa task.
- Kiểm tra tham chiếu trong `StorageCleanup.process()` hiện chỉ kiểm tra avatar, không quét toàn bộ tham chiếu ảnh bài đăng. Không nên coi bảng này là cơ chế tự nhận diện mọi ảnh còn được sử dụng; luồng nghiệp vụ phải gọi `retire()` đúng ảnh cần loại bỏ.

## Ví dụ

Người dùng đổi avatar từ A sang B:

1. Hệ thống tạo task dự phòng cho B rồi upload B.
2. Database cập nhật avatar thành B và tạo task loại bỏ A.
3. Nếu commit thành công: giữ B, xóa task dự phòng của B; thử xóa A ngay sau commit.
4. Nếu rollback: avatar trong database vẫn là A; task loại bỏ A không được lưu; B được lên lịch dọn vì không được sử dụng.

## Mã nguồn liên quan

- [StorageCleanup.java](../real-estate-backend/src/main/java/com/ndnt/services/storage/StorageCleanup.java): tạo task, giữ ảnh, xóa file và retry.
- [ImageStorageService.java](../real-estate-backend/src/main/java/com/ndnt/services/storage/ImageStorageService.java): upload ảnh và đăng ký callback sau commit/rollback.
- [StorageCleanupScheduler.java](../real-estate-backend/src/main/java/com/ndnt/services/storage/StorageCleanupScheduler.java): chạy dọn định kỳ.
- [StorageCleanupRepository.java](../real-estate-backend/src/main/java/com/ndnt/repositories/StorageCleanupRepository.java): chọn task đến hạn và khóa task khi xử lý.
- [Migration PostgreSQL](../real-estate-backend/db/migrations/002_storage_cleanup_postgresql_forward.sql): cấu trúc bảng.
