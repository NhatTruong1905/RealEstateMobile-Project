# Bàn giao Frontend xét duyệt tin

Ngày: 23/10/2026. Worker: Frontend, branch `NhatTruong1905/frontend`.

Kết quả bàn giao: **source/test sẵn review; task outcome failed vì APK gate chưa xác minh được do tải dependency/DNS**. Không tuyên bố toàn bộ nghiệm thu đã pass.

## Commit và phạm vi

Commit triển khai: `265cef947f6c55a355a26738e74189696c924427` — `feat(frontend): implement property approval UI contract v1.1`.

Đã đọc AGENTS/FRONTEND_RULES UTF8 và xác nhận FINAL v1 qua Orca; sau chỉ đạo mới đã đọc và chuyển sang FINAL **v1.1** tại `D:/RealEstateMobile-Project/docs/approval-api-contract.md`. Không sửa Java/config/schema/backend test, không merge/push, không gọi SMTP/email provider/parser thật. Không commit `AGENTS.md`, `docs/agent-rules/` hoặc báo cáo survey chưa commit từ task trước.

## Hành vi đã triển khai

### React web

- `src/screens/seller/PostPropertyScreen.tsx`: form gửi multipart thật qua `sellerApi.create`, loading + ref chống submit lặp, required/trim tiêu đề/địa chỉ/pháp lý, giá/diện tích hữu hạn dương, số phòng/tầng nguyên không âm, tối đa 5 JPG/PNG. Giữ draft khi lỗi, không tự retry mutation; lỗi mạng nhắc kiểm tra tin đã tạo trước khi thử lại.
- Danh mục/phường lấy từ GET `/api/secure/property-options`; dropdown chọn nhãn từ API và gửi ID, phường hiện kèm quận. Loading/error/retry danh mục; không nhập ID nội bộ, không fallback ID đoán. Nếu bỏ chọn phường, backend có thể parse địa chỉ theo contract và trả field error nếu không xác định được.
- Chỉ hiển thị tiếp nhận chờ duyệt khi response có id/status thật và status `Chờ duyệt`; có link tới Tin đăng để mount/fetch lại. Không tự thay trạng thái tại client hoặc tuyên bố email delivered.
- `SellerPropertiesScreen.tsx`, `SellerPropertyRow.tsx`: loading/error/retry fetch thật, nhãn tiếng Việt, ngày ISO/epoch, lý do từ chối từ response; không link public trên row chờ/từ chối. Render text lý do an toàn, không HTML.
- `core/http.ts`: giữ HTTP status và structured field errors (422 và legacy400), thông báo quyền/xung đột/mạng bằng tiếng Việt; multipart để browser tự thêm boundary. `types.ts`: reason/reviewedBy/reviewedAt/createdDate/wardId.
- `mockProperties.ts`: wire tiếng Việt; public mock list/detail chỉ dùng tin `Đang mở bán`. Không dùng mock mutation để giả báo thành công.

### Flutter mobile

- `PostProperty.dart` và part view: danh mục/phường động theo v1.1, loading/error/retry không đoán ID; tạo/sửa giữ dữ liệu khi lỗi; early guard chống gửi lặp; validate số hữu hạn dương và số phòng/tầng nguyên không âm. Giữ cơ chế ảnh cũ/mới hiện có.
- `APIPropertyMixin.dart`: GET options bằng JWT, multipart chặn gửi owner/status từ client; đọc DTO id/status thật (200/201); hiển thị structured422/legacy400 và lỗi401/403/404/409. Lỗi mạng không tự retry, giữ draft. Client có thể inject để test HTTP mà không gọi provider.
- `PropertyDTO.dart`: parse rejectionReason/reviewedBy/reviewedAt/createdDate, DateTime chấp nhận ISO hoặc epoch milliseconds. Owner submit không gửi reason/audit để backend giữ nguyên khi edit; không reset trạng thái và không thêm resubmit.
- Tin của tôi: tách rõ `Từ chối` và `Đã xóa`, lý do thật và ngày đăng, error/retry thay vì giả danh sách rỗng, pull refresh và refetch sau edit/delete. `MainScreen.dart` tăng revision khi tạo trả true để remount/fetch lại danh sách và overview hiện tại.

### Staff Thymeleaf

- Tái sử dụng `real-estate-backend/src/main/resources/templates/property/list.html` và `edit.html`; không tạo Staff React/Flutter.
- List có filter trạng thái, gồm pending; giữ filter khi phân trang. Detail edit có gallery ảnh, lý do và audit từ server. Owner sửa tin readonly nhưng create admin vẫn chọn được người đăng; không đổi backend authorization.
- Status chỉ đọc, nút xét duyệt chỉ cho model pending và quyền ADMIN/STAFF trong template. Backend vẫn kiểm assignment/role độc lập.
- `src/main/resources/static/js/property-approval.js`: dùng POST JSON `/admin/api/properties` generic hiện có, session same-origin và CSRF. Approve có confirm; reject mở dialog nhập reason bắt buộc trim 1..1000, nút xác nhận disabled khi invalid/loading. Không đổi status hidden trước response.
- Xử lý structured422, legacy400 map/list,401/403/404/409 và network; giữ reason khi lỗi. 409 có nút tải trạng thái mới. Success mới thông báo hệ thống sẽ xử lý email và reload detail. Lưu nội dung ở status đã xét duyệt giữ status, không gửi audit/reason mới.

## Mapping wire chính thức

| Wire từ backend | Nhãn người đăng |
|---|---|
| `Chờ duyệt` | Đang chờ duyệt |
| `Đang mở bán` | Đã được duyệt |
| `Từ chối` | Bị từ chối |
| `Đã xóa` | Đã xóa |

Không dùng PUBLISHED/PENDING/REJECTED làm wire; trạng thái thiếu/không nhận dạng hiển thị Chưa rõ.

## Kiểm chứng và cách chạy lại

Các lệnh web chạy tại `C:/Users/admin/orca/workspaces/RealEstateMobile-Project/frontend/real_estate_frontend-web`; mobile tại thư mục sibling `real_estate_frontend-mobile`.

| Kiểm tra | Kết quả |
|---|---|
| Web `npm ci` + cài dev dependencies test | Thành công; lock được cập nhật cho Vitest/Testing Library/jsdom |
| Web `npm test` | **27 tests pass**, 2 file |
| Web `npm run lint` | Pass, không warning/error |
| Web `npm run build` | Pass `tsc -b && vite build`; Vite8.3.4 |
| Flutter `flutter pub get` | Resolve được dependency; môi trường Windows báo plugin cần symlink/Developer Mode, không tự sửa thiết lập máy |
| Flutter `flutter test --no-pub` | **9 tests pass** (8 test mới + smoke hiện có) |
| Flutter `flutter analyze --no-pub --no-fatal-infos` | Exit0, **122 info**, không error/warning; repository hiện có naming/private-type/style info |
| `dart format` các file Dart đổi; Prettier các TS/TSX/JS đổi | Đã chạy |
| `git diff --cached --check` trước commit | Pass |
| Flutter `flutter build apk --debug --no-pub` | Lần Gradle đầu **BUILD FAILED sau9m32s** vì DNS `storage.googleapis.com`, không tải được `io.flutter:armeabi_v7a_debug`/`arm64_v8a_debug` engine JAR; CLI tự retry lần1 không có tiến độ >3phút, worker Ctrl+C đúng exec session theo chỉ đạo Manager, exit1; **APK chưa verified** |

Test web thực thi React form (multipart/file/trim/double-submit/structured-error/giữ draft/lỗi mạng/options retry), danh sách fetch lại sau lỗi, reason escaped và không public link, HTTP status/Bearer/boundary. Test Staff **chạy JS thật trên DOM template hiện có**, kiểm dialog invalid/trim/max1000, confirm approve, payload/session/CSRF, duplicate submit, success refresh,401/403/404/409/422/legacy400/network và edit rejected không reset metadata. Fixture owner materialize riêng binding create/edit để kiểm disabled/selected và đúng một userId trong FormData; đây không phải render Thymeleaf bằng Java.

Test Flutter dùng MockClient: options JWT; multipart owner edit không ghi metadata; DTO ISO/epoch; structured422; thiếu DTO không success;401 mine; UI rejected tách deleted + reason/retry; edit giữ draft/network/double submit; options retry; create pending message và trả true cho caller refresh. Không test nào gọi backend/email/parser thật.

Checkpoint Orca Manager lúc 22:45:41 báo đã cherry-pick source sang QA commit `8c5256b`: `npm ci`, 27/27 web tests, lint và tsc/Vite build đều pass độc lập; Flutter analyze QA exit0/122info khớp. Đây là evidence do Manager cung cấp, không phải worker tự chạy tại QA và chưa phải end-to-end Backend.

## API thật, mock và giới hạn

- Production code gọi endpoint thật theo FINAL v1.1. Tất cả automated tests là mock fetch/MockClient; **chưa chạy end-to-end với backend đã tích hợp** và chưa xác nhận email delivery. Existing `VITE_USE_MOCKS` chỉ phục vụ fallback read cũ, create/options mới không giả success khi backend lỗi.
- Cần Manager/QA cherry-pick với commit Backend trước khi chạy server-render Thymeleaf, kiểm static JS `/js/property-approval.js`, role/assignment/CSRF thực tế, metadata mới, FK options và public visibility. DTO backend cũ tại worktree này chưa có field mới nên không coi test DOM là server-render integration pass.
- Chưa chạy trên thiết bị/emulator hoặc visual screenshot; widget/DOM tests và web production build đã kiểm hành vi, layout cần QA tích hợp.
- APK chưa được xác minh: lần build đầu dừng ở resolve `debugCompileClasspath`/`compileDebugKotlin` do `No such host is known (storage.googleapis.com)` khi tải engine artifact. Không coi đây là compiler error Dart/Kotlin đã được chứng minh, cũng không coi APK build pass; cần rerun khi DNS/dependency cache khả dụng. Không đổi Android config/toolchain hoặc cấu hình mạng của máy.
- Manager báo DNS resolve được trở lại ở checkpoint22:47:59; worker tiếp tục giữ built-in retry. Đến22:49:27, hai file download mới từ22:46:04 vẫn0byte, không output tiến độ; Manager đã cho phép hủy đúng build khi retry hang. Ctrl+C exec session7824 trả exit1; không relaunch thêm và không stop agent.
- Không thêm resubmit, không sửa chính sách chỉnh tin đã duyệt; backend là nguồn trạng thái/reason/audit và quyết định concurrency.

## Bàn giao

Source/test commit trên là đơn vị Manager review/cherry-pick. Báo cáo này được commit riêng sau source để ghi đúng hash triển khai. Không merge hoặc push. Absolute report: `C:/Users/admin/orca/workspaces/RealEstateMobile-Project/frontend/docs/frontend-approval-implementation-report.md`.
