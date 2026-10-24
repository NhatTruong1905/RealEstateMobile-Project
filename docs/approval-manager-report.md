# Báo cáo nghiệm thu Manager

Nhánh tích hợp: `manager/approval-qa-20261023`, worktree `D:/RealEstateMobile-Approval-QA`. Chưa merge main/production, chưa push, chưa chạy migration live và chưa gửi email thật. Rules chỉ cung cấp local, không commit.

## Kết quả trực tiếp kiểm chứng trên checkout QA

| Kiểm tra | Kết quả |
|---|---|
| Backend Maven offline verify, Java21 | PASS: 226 lượt, 0 failure/error/skipped; build/repackage WAR thành công |
| Cấu hình integration | Chỉ profile test, H2; fake mailer, parser/Cloudinary mock; không profile secret |
| React/Staff tests | PASS 27/27 |
| Web lint và TypeScript/Vite production build | PASS |
| Flutter tests | PASS 9/9 |
| Flutter analyzer --no-fatal-infos | Exit0, 122 info, 0 warning/error; baseline cũng122info |
| APK debug | FAILED ở worker: DNS storage.googleapis.com khi tải Flutter artifacts; built-in retry không tiến triển đã dừng; chưa có APK được xác nhận |

Maven có suite selector chạy lặp nên 226 là lượt thực thi, không phải226 case duy nhất. Lệnh tái lập backend từ thư mục real-estate-backend: `mvn -o verify -Dspring.mail.host=127.0.0.1 -Dspring.mail.port=1` với Java21. Frontend: `npm ci`, `npm test`, `npm run lint`, `npm run build`; mobile: `flutter test --no-pub`, `flutter analyze --no-pub --no-fatal-infos` sau resolve packages. Windows pub get có cảnh báo/lỗi symlink Developer Mode nhưng test/analyzer vẫn thực thi được với package config đã sinh.

Log local ignored: `approval-qa-backend-verify.log`, `approval-qa-web-tests.log`, `approval-qa-web-lint.log`, `approval-qa-web-build.log`, `approval-qa-mobile-tests.log`, `approval-qa-mobile-analyze.log` trong docs checkout QA. Backend verify kết thúc 22:57:36 +07 ngày23/10/2026.

## Luồng đã kiểm tra

Tạo tin trả id/status thật và lưu Chờ duyệt; chưa công khai. Staff được phân công/Admin xét duyệt theo quyền hiện có. Từ chối yêu cầu lý do1..1000 sau chuẩn hóa Unicode, lưu reviewer/time; owner đọc được lý do. Mutation sai quyền/thiếu lý do/xung đột bị chặn. Owner sửa không tự gửi duyệt lại. Public/detail/favorites bảo vệ tin riêng tư.

Outbox được ghi cùng transaction, rollback không phát mail. Test fake kiểm tra người nhận từ chủ tin, ba subject tiếng Việt, lý do đã lưu và HTML escaping; email lỗi không rollback bài đăng, retry có backoff/giới hạn. Kiểm tra quyết định lặp/đồng thời và hai delivery đồng thời không tạo event/gửi lặp trong ứng dụng.

Manager bổ sung test render Thymeleaf thật sau ghép hai commit: create owner select hoạt động, edit readonly, nút duyệt chỉ hiện pending, rejected hiển thị lý do, GET `/js/property-approval.js` trả200 và đúng nội dung. Đây là integration server/render cùng test DOM/widget; chưa phải browser/device E2E.

Các finding review đã sửa và kiểm tra: Unicode mail mất dấu; admin same-status save bỏ mất nội dung; owner selector khóa nhầm create; form web bỏ optional fields/network error; migration khác dialect; test nạp secret profile; NBSP/U202F/BOM-only vượt qua required reason.

## Commit nguồn và tích hợp

- Frontend source265cef9, reportc9b6055 -> QA8c5256b, f527d9d.
- Backend sourceeee93cc, report1739cce, fix523692f, report4a6af9a -> QA0c568b3, d75e019, 5f74fc9, 1ba819a.
- Test tích hợp bổ sung và tài liệu Manager được lưu riêng sau các commit nguồn.
- Orca Run `run_55b7db3023ae`: hai survey succeeded; Backend implementation và R-07 succeeded; Frontend failed ở gate APK. Worker đã settlement; release giữ nguyên terminal có sẵn (`external_terminal`, không đóng phiên người dùng).

## Phần chưa kiểm chứng / kết luận

Backend và kiểm tra UI/API/DB/email fake đạt trong môi trường QA. Chưa chấp thuận toàn bộ release vì APK chưa build thành công. Chưa kiểm browser E2E/thiết bị, migration trên MySQL/PostgreSQL native, delivery SMTP/hộp thư thật. Migration mới chỉ smoke-test bằng H2 ở hai compatibility modes. SMTP không có provider idempotency vẫn có rủi ro trùng khi provider đã nhận nhưng ACK mất; không bảo đảm exactly-once bên ngoài.

Ứng dụng mặc định mail fake và worker tắt để an toàn; vận hành thực tế cần migration đúng dialect, cấu hình SMTP, bật worker và URL theo báo cáo Backend. Không đổi cấu hình production trong task. Giữ nhánh QA để review và xử lý gate APK khi môi trường tải dependency hoạt động.
