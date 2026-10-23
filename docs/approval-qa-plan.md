# QA plan và bằng chứng

Contract: `approval-api-contract.md` FINAL v1.1. QA branch: `manager/approval-qa-20261023`, worktree `D:/RealEstateMobile-Approval-QA`.

## Kiểm tra bắt buộc

| Nhóm | Trường hợp | Bằng chứng cần có |
|---|---|---|
| Tạo tin | principal hợp lệ, dữ liệu/FK đúng, response id/status/date thật; pending không public | API + service + DB integration |
| Tạo lỗi | validation, FK không hợp lệ, save/commit rollback | Không property/event/mail |
| Duyệt | STAFF assigned và ADMIN theo quyền sẵn có; pending -> published | DB audit + public list + một event/mail fake |
| Từ chối | reason trim 1..1000; owner thấy reason; nội dung email dùng reason đã lưu | API + UI + DB + fake mail |
| Từ chối lỗi | thiếu/blank/quá dài reason | 422 field error, trạng thái/event không đổi |
| Phân quyền | anonymous, user thường, owner khác, Staff chưa assigned | Security chain 401/403/404, không mutation/mail |
| Visibility | public/mine/detail/favorites; pending/rejected/deleted | Không lộ tin/lý do riêng tư cho người khác |
| Retry/concurrency | same decision lặp, concurrent approve/reject, event được đọc lại | Một quyết định, một event; xung đột 409; không sửa audit/reason sau quyết định |
| Email | tiếp nhận/chấp nhận/từ chối, owner thật, escape HTML, fail/retry/backoff | Fake mailer, không credential/SMTP/provider thật |
| Tính bền vững | transaction rollback, email failure, outbox unique claim | Trạng thái bài không rollback bởi email; job không chạy trước commit |
| UI | form validation/loading/double submit; reason dialog; approve confirm; lỗi API/network và refetch | Unit/component/integration test thực thi |
| Schema | additive forward/rollback, ddl-auto=none, deploy order | DB test; ghi rõ MySQL live chưa kiểm chứng nếu chỉ H2 |
| Regression | backend full tests/package, web lint/typecheck/build/tests, mobile analyze/test/build | Log và số lượng; phân biệt lỗi nền với regression |

## Bằng chứng ban đầu

- Manager chạy targeted baseline `APIPropertyControllerTest,PropertyServiceImplTest`: 9 tests, 0 failures/errors/skipped, BUILD SUCCESS ngày 23/10/2026; log ignored `docs/approval-baseline-backend.log`.
- Maven 3.9.16, Java21; JAVA_HOME chỉ sửa trong process. Worker độc lập báo targeted baseline cùng kết quả.
- Manager chạy full baseline backend trên code gốc với SMTP host loopback/port1: Maven SUCCESS, 194 lượt test, 0 failures/errors/skipped; có integration H2. Repo có JUnit suite selector nên số lượt không đồng nghĩa số test case duy nhất. Log ignored `docs/approval-baseline-full-backend.log`; kết thúc 22:28:19 +07 ngày 23/10/2026.
- Baseline mobile analyzer do Manager chạy: exit0 với `--no-pub --no-fatal-infos`, 122 info, không warning/error; log ignored `docs/approval-baseline-mobile-analyze.log`.
- Frontend survey: web build/lint chưa có dependency; mobile test --no-pub chưa resolve packages. Đây là blocker môi trường trước implementation, chưa phải kết quả tính năng mới.
- Chưa kiểm thử feature mới hoặc browser E2E; chưa có commit implementation ở mốc này.
- Review sớm phát hiện literal tiếng Việt trong PropertyMailOutbox.java bị thay bằng dấu `?`; đã gửi Backend qua Orca `msg_2120950561e1`, yêu cầu sửa encoding và exact-subject/Unicode/escaping assertions trước nghiệm thu.

## Giới hạn phải báo

- Không sử dụng DB/SMTP/email thật. Test fake chứng minh ứng dụng tạo/xử lý event, không chứng minh thư tới hộp thư thật.
- SMTP không có provider idempotency không bảo đảm exactly-once khi provider nhận nhưng ACK mất; không được bỏ qua rủi ro này khi báo kết quả.
- Không có resubmit mới; owner edit giữ status/reason/audit theo contract. Chính sách duyệt lại sau chỉnh sửa là ngoài task.
- Không merge main/production; tích hợp QA chỉ sau review và các quality gate bắt buộc đạt.

## Findings trong review sớm (chưa nghiệm thu bản sửa)

| ID | Phát hiện | Worker / xử lý |
|---|---|---|
| R-01 | Mail literal mất dấu thành `?` | Backend xác nhận sửa, chờ exact-subject/HTML escape tests |
| R-02 | Same-status admin save trả sớm làm bỏ mất sửa title/price | Backend xác nhận đổi transitioned flag, giữ audit/reason và chỉ enqueue khi transition thật |
| R-03 | Admin owner selector bị disabled cho cả create, mất khả năng tạo thay khách | Frontend nhận yêu cầu chỉ readonly khi edit, giữ create selection và label đúng owner |
| R-04 | Bản form web mới bỏ trường optional cũ và network error hiện raw tiếng Anh | Frontend nhận yêu cầu giữ field optional, validation nguyên không âm và thông báo tiếng Việt/không retry mù |
| R-05 | Local MySQL nhưng prod PostgreSQL; SQL AUTO_INCREMENT không dùng chung được | Backend phát hiện và đang bổ sung script PostgreSQL + kiểm tra H2 PostgreSQL mode; không gọi DB live |
| R-06 | Test profile vẫn kèm include `secret` do bootstrap đọc include trước TestPropertySource | Backend đang tách cấu hình test/command; không được dựa vào secret để đạt test |
| R-07 | Backend `trim().strip()` coi NBSP/U+202F-only là lý do hợp lệ, khác JS trim | Manager kiểm chứng Java21 JShell trả `false` với blank normalization; gửi Backend msg_8293e39d01d3 yêu cầu fix + regression HTTP422/no event trước nghiệm thu |

Mọi finding chỉ đóng sau khi Manager đọc bản sửa và chạy kiểm tra phù hợp.
