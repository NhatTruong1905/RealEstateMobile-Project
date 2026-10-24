# Backend approval implementation — FINAL v1.1

## Kết quả và phạm vi
Worktree `C:/Users/admin/orca/workspaces/RealEstateMobile-Project/backend`, branch `NhatTruong1905/backend`. Đã đọc lại AGENTS.md/BACKEND_RULES và contract tuyệt đối `D:/RealEstateMobile-Project/docs/approval-api-contract.md`; áp dụng các bổ sung Manager về options, sửa nội dung cùng status và migration PostgreSQL. Không sửa templates/property hoặc frontend, không apply migration live, không gửi SMTP thật, không push/merge main. Rules vẫn untracked và không được stage/commit.

Giữ nguyên DB/API strings: `Chờ duyệt`, `Đang mở bán`, `Từ chối`, `Đã xóa`; enum và route tạo/duyệt cũ không đổi. Endpoint mới duy nhất do FINAL v1.1 cho phép: GET `/api/secure/property-options`, JWT, projection types/categories `{id,name}`, wards `{id,name,districtName}` từ service hiện có.

## API và bảo vệ nghiệp vụ
- POST multipart `/api/secure/properties`: owner lấy từ authenticated principal/account active; create ép pending, bỏ status/reason/reviewer/audit/userId/email do client gửi. Update phải là owner, giữ status/reason/reviewer/time/created audit; không resubmit. Lưu managed entity, trả DTO đã flush gồm id/status/date thật.
- POST JSON `/admin/api/properties`: giữ session + CSRF và form đầy đủ. STAFF phải assigned; ADMIN giữ quyền. Cập nhật hiện có không đổi owner qua payload. Create admin vẫn chọn account owner tồn tại như chức năng cũ, email snapshot lấy từ account trong DB.
- Chỉ pending -> published/rejected; lý do rejected normalize Unicode whitespace hai đầu, sau đó validate 1..1000. Trả 422 envelope `{message,detail:"VALIDATION_ERROR",data:{rejectionReason:"..."}}`; FK thiếu/sai trả cùng envelope theo field. Form Bean Validation cũ giữ 400/list. 403 thiếu quyền, 404 missing/private detail, 409 transition xung đột/deleted edit.
- Cùng quyết định giữ reason/audit và không thêm event; cùng trạng thái vẫn cho Staff/Admin sửa nội dung theo chỉ dẫn Manager bổ sung. Payload giống hệt không dirty JPA. Quyết định khác sau review bị 409. Pessimistic property row lock serialize admin/owner mutations/delete.
- Explicit wardId không gọi parser. Khi thiếu wardId, dùng parser/address resolver hiện có; lỗi/không tìm được phường trả422, không lưu/mail. Xác minh type/category/ward tồn tại, không để FK-null thành DB500.
- Secure detail luôn đòi JWT: nonpublished chỉ owner hoặc reviewer có quyền; published đọc rộng nhưng bỏ review metadata nếu không owner/reviewer. Public list chỉ published bằng exact status equality, không có rejectionReason/reviewedBy/reviewedAt. Mine chỉ principal, có metadata riêng tư. Favorites lọc visibility; thêm favorite phải được xem detail, danh sách propertyIds sai trả422. Delete mobile owner-only; delete admin reviewer/assignment. Secure errors JWT401/CSRF403 vẫn đi qua filter chain cũ.

## Persistence, migration và triển khai
Cột nullable mới `property.rejection_reason VARCHAR(1000)`, `reviewed_by INTEGER`, `reviewed_at TIMESTAMP(6)`. reviewed_by là user id snapshot, không FK cascade để không xóa lịch sử audit. Bảng `property_mail_outbox` snapshot recipient/subject/text/html từ dữ liệu đã lưu, property_id và event_type, unique event_key, state/attempts/next_attempt_at/created_at/sent_at/last_error; index due. Không FK property_id để event bền khi legacy hard deletion xảy ra.

Chọn ĐÚNG MỘT forward theo engine:
- MySQL8: `real-estate-backend/db/migrations/001_property_approval_forward.sql`.
- PostgreSQL (profile prod): `.../001_property_approval_postgresql_forward.sql`; identity và timezone cho Instant outbox.
- Rollback chung: `.../001_property_approval_rollback.sql`.

Không có Flyway/Liquibase; `ddl-auto=none` giữ nguyên. Operator backup, apply schema trên môi trường kiểm soát trước deploy app; bảo đảm MySQL UTF8MB4 để lưu tiếng Việt. Chỉ một phiên migration, scripts không idempotent tự chạy lại. Cột nullable tương thích dữ liệu cũ, không bịa reviewer/date. Rollback: dừng worker và writers, drain/export pending events, rollback app trước, rồi script drop outbox/cột; rollback mất metadata mới nếu không export. MySQL DDL implicit commit; không dựa vào rollback transaction để hoàn tác DDL. Chỉ smoke SQL trên H2 modes, chưa xác minh native MySQL/PostgreSQL hoặc DB thật. Chưa chạy script lên live.

## Email và outbox
Property save + enqueue cùng transaction: rollback không để event tồn tại; scheduler/delivery transaction riêng chỉ thấy committed rows. Recipient luôn snapshot từ account owner thật; username/title/reason/date snapshot để retry giữ đúng quyết định. Ba subject tiếng Việt đúng BACKEND_RULES; HTML escape với UTF8, text alternative, giờ theo config. Link approved chỉ thêm khi cấu hình prefix. Không hứa resubmit trong mail rejected.

Key `{propertyId}:RECEIVED|APPROVED|REJECTED`; không resubmit nên mỗi event type chỉ một lần, unique DB constraint chống enqueue trùng. Delivery REQUIRES_NEW khóa row trong lúc gọi mailer; worker khác chờ rồi thấy SENT hoặc next_attempt tương lai. Không dùng lease có nguy cơ hết hạn trong lúc send. SMTP connection/read/write timeout 5 giây. Bounded exponential retry mặc định tối đa5, delay60s nhân2, cap86400s; FAILED sau hết lượt. Last_error chỉ mã DELIVERY_FAILED, log event id/attempt không log recipient/body/exception chứa PII. Worker poll20 events mỗi10s, không cùng transaction với bài đăng nên provider fail không rollback trạng thái.

Mặc định SAFE: `property.mail.mode=fake`, `property.mail.worker-enabled=false`; event được ghi bền nhưng chưa tự gửi. Nếu bật worker ở fake mode thì SENT là gửi mô phỏng, không phải email đã giao thật. Chuyển SMTP chỉ sau operator cấu hình và cho phép; không bật SMTP trong test. Cấu hình môi trường: PROPERTY_MAIL_MODE, PROPERTY_MAIL_WORKER_ENABLED, PROPERTY_MAIL_MAX_ATTEMPTS, PROPERTY_MAIL_RETRY_SECONDS, PROPERTY_MAIL_POLL_MS, PROPERTY_MAIL_ZONE (mặc định Asia/Ho_Chi_Minh), PROPERTY_URL_PREFIX (ví dụ https://example.invalid/properties/). Cấu hình JavaMailSender qua SPRING_MAIL_HOST/PORT/USERNAME/PASSWORD và SMTP auth/starttls theo provider, không hardcode credentials. Tái sử dụng JavaMailSender infrastructure; OTP service cũ không thay đổi.

Giới hạn: external SMTP không có provider idempotency nên không đảm bảo exactly-once khi SMTP đã nhận nhưng ACK mất hoặc process chết trước commit SENT; retry có thể giao trùng bên ngoài. DB khóa chống hai application workers gửi đồng thời và unique key chống tạo event trùng, không giải quyết ACK ambiguity. Create không có request idempotency key: frontend không blind retry tạo bài khi mất response; mỗi bài thật có một RECEIVED event. Cloudinary upload là side effect ngoài DB; rollback DB không xóa asset đã upload, như hạ tầng cũ. Account thiếu/sai email sẽ retry/fail delivery, bài vẫn tồn tại; cần theo dõi FAILED; sửa account không tự sửa recipient snapshot đã lưu, nên reconciliation/redrive event phải qua quy trình vận hành có kiểm soát (không có endpoint redrive mới trong scope).

## Kiểm thử và cách tái lập
Maven executable cục bộ: `C:/Users/admin/.m2/wrapper/dists/apache-maven-3.9.16/0daed3be3ebd1c706f0e69e8b07c6b73f5cc4ea3dfce72a8d0ec2e849ca2ddb0/bin/mvn.cmd`; JAVA_HOME process `D:/Java/jdk-21.0.12.1`. Chạy từ root worktree với `-f real-estate-backend/pom.xml`, hoặc cd real-estate-backend. Không dùng app config mặc định để start live.

Commands:
`mvn -f real-estate-backend/pom.xml -Dtest=PropertyApprovalIntegrationTest,PropertyApprovalMigrationTest,PropertyServiceImplTest,APIPropertyControllerTest test`
`mvn -f real-estate-backend/pom.xml verify`
Sau cache dependencies đầy đủ có thể thêm `-o`. WAR tại `real-estate-backend/target/real-estate-backend-0.0.1-SNAPSHOT.war`; không deploy artifact này trong task.

PropertyApprovalIntegrationTest dùng SpringBoot real filter chain + MockMvc/H2, parser/Cloudinary/mailer MockitoBean. Hai integration contexts dùng `spring.config.location=classpath:test.properties` để bỏ application.properties/include secret; test profile fake và worker off. JWT ký bằng test JWT_SECRET, DTO principal từ fixture active DB account; session dùng Spring Security user(staff).roles(STAFF) + csrf(). Fixture IDs sinh runtime, không hardcode ID production; types/categories/wards được persist trước tạo. Manager có thể chạy cùng tests sau cherry-pick FE templates; smoke GET admin create/edit render Thymeleaf thật.

Bao phủ create valid/id/status/date/trusted owner/no parser explicit ward; invalid FK/parser/Bean validation không save/event; parser resolve success; options401/shape; assigned approval/rejection và owner/nonassigned/role/CSRF guard; missing/blank/too-long reason và boundary1000; exact Unicode subjects/reason HTML escaping; owner edit giữ review và admin same-status edit; detail/public/favorites privacy; delete guard; rollback transaction không event; bounded failure/backoff và duplicate delivery; concurrency same/conflicting decisions và two-worker deliver; additive migration/unique/rollback preserve old rows. Các test hiện có được chỉnh đúng contract bảo mật (legacy delete giờ authenticated admin; unit dùng locked repository), không bỏ case.

## Evidence và bàn giao trước fix R-07
Implementation commit: `eee93cc5035e9c11329c7a2014ae33a84e761727` (27 files: Java/API/entity/repository/access/outbox, cấu hình safe defaults, ba SQL scripts, test và survey). Báo cáo này được commit riêng sau code để ghi được hash implementation; lấy hash documentation commit từ bàn giao Orca/git log.

Final command đã thực thi thành công: Maven cached executable + `-o -f real-estate-backend/pom.xml verify`, JAVA_HOME process như trên. Kết thúc `2026-10-23T22:49:25+07:00`, duration 01:09, **BUILD SUCCESS**; 222 executions, 0 failures/errors/skipped. Repo có @Suite chọn toàn package nên mỗi test được chạy cả trực tiếp và qua suite (111 test cases duy nhất); bao gồm 12 approval integration cases và 2 migration compatibility cases. Cả DeleteOperationIntegrationTest và PropertyApprovalIntegrationTest log chỉ một active profile `test`, không `secret`, JDBC H2 in-memory. Final gate có khôi phục `assignmentIds` mapping cũ và assertion detail assignment để giữ tương thích.

Compile main150 sources/test26 sources bằng javac21, full tests, WAR packaging + Spring Boot repackage đều pass. WAR ~155MB tại path trên; SHA256 `E19D97B201417AEE8C10B5F68D1BDCF3828C74D17972D77302BCB0E19DD1E788`. Local evidence ignored: `real-estate-backend/target/approval-final-verify.log` và `target/surefire-reports/TEST-*.xml`; không commit logs/target/war. Native DB/provider không được gọi; các H2 modes chỉ compatibility smoke, không đại diện native DB pass.

Lượt offline verify trước thiếu dependency Maven WAR plugin sau khi toàn tests đã pass; đã tải plugin dependencies từ Maven Central bằng Maven online và build thành công, sau đó rerun offline final trên trạng thái code cuối. Các test fixture lỗi ở lượt đầu đã sửa (duplicate request parameter, plural propertyIds, tên phường unique), không bỏ case. Chỉ cấu hình test.properties không đủ loại include secret từ main config-data; hai integration annotations dùng config.location riêng đã giải quyết và được log xác nhận.

Remaining deployment/review: Manager review/cherry-pick code và documentation commit; tích hợp FE templates ở worktree QA và chạy lại smoke render/static asset do FE sở hữu; operator review/apply đúng migration dialect trong maintenance window rồi bật provider/worker sau cấu hình. Không có blocker implementation tại final gate, nhưng native DB migration và email provider delivery chưa được nghiệm thu live trong task này. Không có lint/typecheck plugin riêng trong pom; javac21/test/package là checks phù hợp, git diff --check kiểm whitespace. Các warning deprecated/unchecked/Mockito agent là baseline, không được tuyên bố sạch warning.


## Fix R-07 — Unicode whitespace (23/10/2026)
Manager review phát hiện Java21 trim().strip() không loại NBSP U+00A0 và NARROW NO-BREAK SPACE U+202F. Fix riêng `523692f0acb9550a0117d4bb810168a6980d039b`, không amend implementation cũ. Chỉ thay PropertyServiceImpl và PropertyApprovalIntegrationTest; cập nhật báo cáo bằng documentation commit riêng. Không đổi contract/route/schema/UI, không commit rules, không merge/push hoặc SMTP thật.

Normalization quét code points ở hai đầu theo `Character.isWhitespace(cp) || Character.isSpaceChar(cp) || cp == 0xFEFF`, giữ nguyên mọi nội dung/khoảng trắng ở giữa. Validate chuỗi sau normalize dài 1..1000; null hoặc whitespace-only trở thành rỗng và trả structured422. Chỉ dùng trong transition reject thật, giữ nguyên duplicate/permission/audit semantics đã chốt.

Hai HTTP regression tests với real session/CSRF + assigned Staff/H2:
- NBSP, U202F, FEFF riêng và mixed ASCII/Unicode whitespace đều422 VALIDATION_ERROR/data.rejectionReason; DB vẫn pending, reason/reviewer/time null, modifiedDate không đổi, chỉ1 RECEIVED event, mailer không gọi.
- Padding Unicode/BOM dài hơn1000 raw được loại trước kiểm tra độ dài; reason thật có NBSP/U202F bên trong giữ nguyên, API/DB khớp, REJECTED event text/HTML dùng đúng stored reason và escape HTML, không còn BOM padding; không gửi mail thật.

Cùng Maven cached executable và JAVA_HOME process đã nêu, từ root worktree:
`mvn -o -f real-estate-backend/pom.xml -Dtest=PropertyApprovalIntegrationTest#unicodeWhitespaceOnlyReasonIsRejectedWithoutMutationOrEvent+paddedUnicodeReasonIsNormalizedBeforeLengthCheckAndMailSnapshot test`
PASS 2 tests, 0 failure/error/skip; 22:54:37 +07, duration39.733s.
`mvn -o -f real-estate-backend/pom.xml verify`
**BUILD SUCCESS**, 226 executions (113 cases duy nhất do suite tổng chạy lặp), 0 failure/error/skip; 22:55:42 +07, duration52.478s, WAR và Spring Boot repackage thành công. Cả2 integration contexts chỉ active profile test, config.location=classpath:test.properties, JDBC H2 và mailer fake/mock, worker off. Evidence ignored: target/r07-targeted.log và target/r07-full-verify.log. Lượt script khởi đầu lỗi escape khiến selector chạy0 tests không được dùng làm evidence; các kết quả PASS trên đã compile và chạy thật2 tests mới rồi full suite.

git diff --cached --check pass trước fix commit; chỉ docs/source/test được stage cụ thể. Các giới hạn native DB/provider/SMTP ACK ambiguity và deploy approval ở trên giữ nguyên; sẵn sàng Manager cherry-pick base implementation + fix vào QA.
