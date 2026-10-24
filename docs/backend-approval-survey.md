# Khảo sát backend xét duyệt tin — 23/10/2026

## Phạm vi và rules
Đã đọc đầy đủ UTF8 `AGENTS.md` và `docs/agent-rules/BACKEND_RULES.md` tại worktree; không cần fallback D:. Vai trò Backend Worker: tái sử dụng trạng thái/controller/service hiện có, kiểm tra auth Staff/ownership/visibility, từ chối phải có lý do được lưu và owner đọc được, email sau commit có chống trùng/retry; không tự thiết kế resubmit. Task hiện tại CHỈ khảo sát và viết tài liệu, chờ Manager chốt contract; không sửa nghiệp vụ, không commit/chuyển nhánh/merge, không gửi email thật.

Cwd tuyệt đối: `C:/Users/admin/orca/workspaces/RealEstateMobile-Project/backend`.
Branch: `NhatTruong1905/backend`; HEAD `ccb2700aa235e2648036679fb5384027d1c4c7da`.
Git status ban đầu: `?? AGENTS.md`, `?? docs/agent-rules/`; giữ nguyên các file này. File duy nhất task tạo: `docs/backend-approval-survey.md`.
Kênh Orca đã xác minh bằng check thành công và status `msg_2ed718bb7684`. Không giả định file untracked được chia sẻ qua worktree khác; Manager đọc báo cáo bằng đường dẫn tuyệt đối ở trên.

## Stack và nguồn bằng chứng
Mọi đường dẫn sau tương đối với `real-estate-backend/`, trừ khi ghi khác.
- `pom.xml`: Java 21, Spring Boot 4.1.0, Spring MVC/Security/Data JPA/Validation/Thymeleaf/Mail, Hibernate, ModelMapper, MySQL và PostgreSQL runtime, H2 và Mockito/Spring Security test. Đóng gói WAR; Cloudinary cho ảnh; Spring AI cho parse địa chỉ.
- `src/main/java/com/ndnt/model/enums/StatusProperty.java`, `model/entity/PropertyEntity.java`, `services/impl/PropertyServiceImpl.java`: trạng thái và persistence.
- `controllers/api/APIPropertyController.java`, `controllers/admin/PropertyController.java`: endpoint.
- `configs/ApiSecurityConfig.java`, `configs/SpringSecurityConfig.java`, `filters/JwtFilter.java`: JWT API và session admin.
- `model/dto/PropertyDTO.java`, `model/dto/BaseDTO.java`, `model/dto/request/PropertyRequestDTO.java`, `model/dto/response/ResponseDTO.java`, `converter/PropertyConverter.java`, `repositories/PropertyRepository.java`: payload, search, response, mapping.
- `model/entity/BaseEntity.java`, `configs/JpaAuditingConfig.java`: auditing chung.
- `services/impl/EmailServiceImpl.java`, `RealEstateBackendApplication.java`, `src/main/resources/application*.properties`: mail/config.
- `src/main/resources/templates/property/{edit,list}.html`: UI admin thuộc backend; chưa khảo sát mobile/frontend ngoài phạm vi.

## Mapping trạng thái và transition thực tế
| Enum Java | Chuỗi lưu DB và trả API | Nghiệp vụ | Hành vi hiện tại |
|---|---|---|---|
| PENDING | Chờ duyệt | chờ duyệt | create không có id luôn ép trạng thái này |
| PUBLISHED | Đang mở bán | được duyệt/công khai | public list ép search.status bằng chuỗi này |
| REJECTED | Từ chối | bị từ chối | có thể gửi qua generic update, không có lý do |
| DELETED | Đã xóa | xóa mềm | delete đặt trạng thái này |

`property.status` là String, KHÔNG lưu enum name. Entity mặc định PENDING.getStatus(); service create ép lại. Generic update có id chấp nhận status không-null từ request; không có whitelist, state machine, guard chỉ PENDING được duyệt, optimistic version hoặc khóa repository. Vì converter map DTO sang entity mới, update bỏ status không bảo đảm giữ status cũ (phụ thuộc ModelMapper); cần kiểm chứng và sửa khi có contract. Delete không hạn chế trạng thái nguồn. Không có transition resubmit chuyên biệt; generic update cho phép ghi lại trạng thái và không tự đưa REJECTED về PENDING. Không coi lỗ hổng update hiện tại là chức năng gửi duyệt lại đã được thiết kế.

## Contract HIỆN CÓ (không phải contract đề xuất đã được duyệt)
URL dưới đây tương đối với base URL triển khai.
| Method/route | Auth | Request | Response/đặc điểm |
|---|---|---|---|
| GET /api/properties | public | PropertyRequestDTO query + page=1, limit=6 | 200 ResponseDTO.data={content,currentPage,totalItems,totalPages}; ép status=Đang mở bán |
| GET /api/secure/properties | Bearer JWT, authenticated | không body | 200 {message:Success,data:[PropertyDTO]}; owner từ principal; không phân trang, không lọc trạng thái kể cả deleted |
| POST /api/secure/properties | Bearer JWT | multipart/form-data PropertyDTO; id có thì update | validation 400 list string; user không tìm thấy 403 body rỗng; 200 {message:Success,data:input DTO} |
| GET /api/secure/properties/{id} | Bearer JWT | id | 200 {message:Success,data:PropertyDTO}; nhánh null trả 400 Fail nhưng service Optional.get thực tế ném khi thiếu |
| DELETE /api/secure/properties/{id} | Bearer JWT | id | 200 {message:Success}; soft delete; không ownership guard |
| GET /admin/properties-list | session STAFF hoặc ADMIN | search DTO, page=1,size=8 | HTML property/list; sort id desc; STAFF bị ép staffId hiện tại qua assignment join; status có thể lọc Chờ duyệt, không có JSON queue riêng |
| GET /admin/properties-edit | session STAFF hoặc ADMIN | model | HTML form tạo, tất cả enum status |
| GET /admin/properties-edit-{id} | session STAFF hoặc ADMIN | id | HTML form sửa; STAFF phải được phân công qua isStaffOfProperty; lỗi view error/error |
| POST /admin/api/properties | session STAFF hoặc ADMIN + CSRF | application/json PropertyDTO | 200 ResponseDTO data=input DTO, message thêm/cập nhật; 400 list string validation; ghi trạng thái là cơ chế duyệt hiện có |
| DELETE /admin/api/properties/{id} | session STAFF hoặc ADMIN + CSRF | id | 204; soft delete |

Ngoài ra GET/POST `/api/secure/favorite-properties` dùng JWT; danh sách favorites không lọc PUBLISHED nên có thể hiển thị tin chưa công khai/xóa nếu đã lưu. Không thấy POST approve/reject riêng hoặc pending queue API cho mobile Staff.

### Payload thật
PropertyDTO kế thừa id, createdDate, createdBy, modifiedDate, modifiedBy. Trường: userId/userFullname/userEmail/userPhone; typeId/typeName/typeCode; categoryId/categoryName/categoryCode; title, description, address, city, wardId, addressDetail, price, area, floorCount, bedroomCount, bathroomCount, direction, legal, status, images (list URL), assignmentIds; files multipart có JsonIgnore.
Validation DTO hiện chỉ title/address/legal NotBlank, price/area NotNull Positive. Entity đòi user/type/category/ward non-null nhưng DTO không validate các FK tương ứng. API mobile ghi đè userId từ principal, song không xác minh id update thuộc owner; nguy cơ đổi chủ tin khác. Admin write/delete không kiểm tra assignment như GET edit.
Ví dụ multipart create tối thiểu theo DTO (FK phải tồn tại): title=Nhà mẫu; address=123 đường mẫu; legal=Sổ hồng; price=1000000000; area=60; typeId=1; categoryId=1; wardId=1; files=<file tùy chọn>. Không cần status/userId khi tạo mobile.
Ví dụ JSON cập nhật admin hiện tại: {"id":123,"title":"Nhà mẫu","address":"123 đường mẫu","legal":"Sổ hồng","price":1000000000,"area":60,"status":"Từ chối","userId":1,"typeId":1,"categoryId":1,"wardId":1}. Đây là update đầy đủ, KHÔNG phải reject DTO tối thiểu hay thao tác an toàn đã thiết kế.
ResponseDTO có data/message/detail; ví dụ list: {"message":"Success","data":{"content":[{"id":123,"title":"Nhà mẫu","status":"Đang mở bán"}],"currentPage":1,"totalItems":1,"totalPages":1},"detail":null}. Trường khác lược bỏ trong ví dụ. Create/update trả DTO đầu vào, không map lại entity sau save; id/status/audit được sinh hoặc thay đổi ở entity không được gán lại DTO, nên response có thể thiếu id mới và status thực sự đã lưu.
PropertyRequestDTO có title,toPrice,fromPrice,area,address,districtId,wardId,floorCount,bedroomCount,bathroomCount,direction,legal,staffId,categoryId,typeId,status. Search status dùng LIKE chứ không equality. Không validate page/limit; giá trị không hợp lệ có thể gây exception.
JWT thiếu/sai/expired trả 401 qua sendError, format phụ thuộc servlet; chưa có contract lỗi thống nhất. Session chưa login có thể redirect trang login; role/CSRF sai bị 403/error page. Không có nhánh 409 transition, 422 lý do, 404 chuẩn cho missing property. Chưa kiểm chứng HTTP runtime.

## Rejection reason, schema, ownership và visibility
Không có rejectionReason/rejectedBy/rejectedAt trong PropertyEntity hoặc PropertyDTO; không có validation lý do, lưu lý do hay endpoint owner truy xuất lý do. BaseEntity chỉ audit created/modified, không đủ lịch sử hoặc version transition. Repository không có lock/CAS. Không tìm thấy migration SQL/Flyway/Liquibase trong tracked repository; application và prod đều ddl-auto=none. Bổ sung cột cần migration SQL có rollback và kế hoạch deploy rõ ràng, chưa tự tạo migration trong survey. DB runtime chưa được truy cập nên chưa xác nhận schema/data thực tế ngoài entity/config.
Public list ẩn pending/rejected/deleted theo status; secure detail chỉ đòi authenticated, không guard owner/Staff hoặc published. Secure delete/update không guard owner; admin write/delete không guard assignment. PropertyDTO còn có contact email/phone owner qua mapping, cần chốt quyền hiển thị trước khi thêm lý do riêng tư. getPropertyOfUser query đúng userId nhưng trả mọi status. Favorites có gap lọc visibility nêu trên.

## Email hiện có và gap
EmailServiceImpl chỉ sendOtpEmail; JavaMailSender optional, MimeMessageHelper HTML UTF8, sender lấy spring.mail.username với fallback. Có @Async nhưng tìm toàn src chưa thấy @EnableAsync; chưa thể khẳng định chạy background. Chưa có mail cho create/approve/reject, after-commit event, outbox, durable queue/retry/backoff hoặc idempotency. Hàm OTP catch lỗi và log, template nối trực tiếp name chưa escape; log OTP/email cần tránh tái dùng cách logging này cho luồng mới. PropertyServiceImpl @Transactional cấp class nhưng không inject EmailService, không phát sự kiện sau commit. Recipient phải lấy user entity đáng tin cậy, không dùng userEmail từ payload DTO. Chưa có cấu hình property URL/timezone cho mail được xác nhận.
Config keys cần đánh giá: spring.mail.host/port/username/password, mail.smtp.auth/starttls.enable; DATABASE_URL/DATABASE_USERNAME/DATABASE_PASSWORD/PORT xuất hiện dạng env placeholder. Không chép giá trị secret vào báo cáo. Chưa chọn provider, không đổi cấu hình và không gửi mail. Phương án tối thiểu cần Manager chốt: persistent outbox có unique event key + retry worker để đáp ứng durability/chống trùng, hoặc after-commit sender với giới hạn retry phải công khai; riêng @Async không đáp ứng durable retry.

## UI backend và test/build
Admin edit dùng select tất cả StatusProperty qua st.status; submit JSON POST cùng route hiện có và header X-CSRF-TOKEN. Không thấy input lý do từ chối hoặc approve/reject riêng. Admin list áp assignment cho Staff, edit GET kiểm tra assignment; quyền write chưa tương ứng. Mobile UI không nằm phạm vi khảo sát.
Có 24 Java test files trong src/test (controller/service và integration delete). Đã đọc APIPropertyControllerTest và PropertyServiceImplTest: standalone MockMvc không chạy security filter chain; controller tests list/mine/detail/delete/favorite, không test multipart create; service tests find/delete/mine, không test create/update/approval/mail. Case detail missing mock trả null không phản ánh Optional.get trong service thật. Không tìm thấy test lý do/transition/concurrency/email/retry vì chưa có chức năng. Có spring-security-test, H2, Mockito đủ nền tảng bổ sung test.
CI `.github/workflows/backend-ci-cd.yml` dùng JDK21, `mvn clean test`; Dockerfile Maven3.9.11/JDK21 build `mvn clean package -DskipTests`. Không thấy lint/typecheck plugin riêng. Local Java21.0.12.1 có sẵn; `Get-Command mvn` không tìm thấy Maven trong PATH và repo không có mvnw. Vì vậy chưa chạy được test/build tại terminal này; chưa cài công cụ hoặc dùng Docker tự khởi động dịch vụ. Không tuyên bố test pass. Survey không cần chạy app kết nối DB/provider thật.

## Các quyết định cần Manager chốt trước implementation
1. Giữ chuỗi status hiện tại ở API/DB; chọn tái sử dụng generic admin update với reject validation hay bổ sung action route tương thích, response nên map entity thật sau save. Mobile Staff hiện không có moderation JSON endpoint bằng JWT.
2. Chốt STAFF được duyệt mọi pending hay chỉ assigned, ADMIN có quyền tương đương; đóng guard ở write endpoint/service và ownership mobile/detail/delete, xác định visibility/contact/reason.
3. Chốt chỉ PENDING -> PUBLISHED/REJECTED; click lặp same action trả 200 idempotent hay 409; cạnh tranh dùng version/CAS/lock. Không tự cho phép resubmit, cần quyết định riêng nếu muốn.
4. Chốt tên/độ dài lý do (đề xuất rejectionReason trim 1..1000), trường reviewer/time và migration/rollback; owner-only reason qua mine/detail theo quyền.
5. Chốt outbox/retry/idempotency schema và provider config; mail tiếp nhận/chấp nhận/từ chối sau commit, HTML escape, link config, fake mailer cho test.
6. Bổ sung unit/integration với security thật: create pending và không public, fail không mail, approve/reject đúng quyền/assignment, thiếu/blank reason 4xx không update/mail, owner đọc reason và người khác bị chặn, duplicate/concurrent requests, provider fail vẫn giữ trạng thái và retry, migration rollback, regression chức năng cũ. Cần Maven hoặc môi trường build được cung cấp để thực thi.

Không có implementation, migration, commit hoặc email thật trong lần khảo sát này. Các gap là kết luận đọc source; trạng thái DB/HTTP thực tế và test runtime vẫn chưa xác minh.

## Cập nhật cuối từ Manager và kiểm chứng build
Manager xác nhận giữ giới hạn assignment cho Staff, ưu tiên endpoint cũ, reason max1000 và đánh giá additive migration reviewedBy/reviewedAt; chưa phải lệnh implementation. Đã kiểm tra lại không có resubmit chuyên biệt. Đề xuất tối thiểu: bổ sung field vào entity/DTO + SQL additive/rollback do ddl-auto=none; guard ownership/assignment và status transition tại service; tận dụng POST admin cũ khi cập nhật trạng thái, không bắt Frontend đổi route; bổ sung reason vào mine/detail được kiểm quyền; mail event/outbox sau commit. Migration/version/outbox vẫn cần Manager duyệt tác động schema trước khi viết.
Manager cung cấp Maven cache ngoài PATH và JDK, nên giới hạn Maven nêu ở phần trước đã được giải quyết cho targeted tests. Đã chạy offline bằng Maven `C:/Users/admin/.m2/wrapper/dists/apache-maven-3.9.16/0daed3be3ebd1c706f0e69e8b07c6b73f5cc4ea3dfce72a8d0ec2e849ca2ddb0/bin/mvn.cmd` với JAVA_HOME process `D:/Java/jdk-21.0.12.1`: `-o -Dtest=APIPropertyControllerTest,PropertyServiceImplTest test` tại real-estate-backend. BUILD SUCCESS: 9 tests, 0 failure/error/skipped; compile 140 main và 24 test sources; hoàn tất 22:22:17 +07 ngày 23/10/2026. Chỉ chạy unit mocks không kết nối DB/SMTP; chưa chạy toàn suite hoặc package WAR. Evidence cục bộ ignored: `real-estate-backend/target/surefire-reports/`. Có warnings deprecated/unchecked sẵn có và Mockito dynamic agent, không có lỗi compile.

## Đối chiếu DRAFT contract và quyết định cuối Manager
Đã đọc UTF8 `D:/RealEstateMobile-Project/docs/approval-api-contract.md` (header còn DRAFT). Mapping/endpoint khớp khảo sát; không blocker thiết kế so với quyết định Manager: STAFF assigned, ADMIN giữ quyền; PENDING -> PUBLISHED/REJECTED, lặp cùng quyết định 200/no event, conflict 409; owner edit giữ status/reason/audit, không đổi owner/reviewer, không resubmit. Contract nên thay câu cuối về sửa/gửi lại còn chờ khảo sát bằng quyết định owner-edit này. Secure detail ghi “công khai nếu published” cần hiểu vẫn Bearer JWT theo route, chỉ dữ liệu published được đọc rộng; reason/audit vẫn chỉ owner/reviewer có quyền, kể cả sau trạng thái thay đổi. Nên ghi rõ delete ownership/assignment và favorites lọc published để đóng gap liên quan visibility. Envelope 422 mới tương thích lỗi 400/list hiện tại nếu Frontend xử lý cả hai. Existing auditing fields từ client phải bỏ qua tương tự reviewer, không chỉ bỏ status.
Đề xuất migration cụ thể (chưa thực hiện): property thêm nullable rejection_reason VARCHAR(1000), reviewed_by (ưu tiên FK user.id nullable, audit DTO chỉ lộ theo quyền), reviewed_at timestamp; cột nullable giữ bản ghi cũ hợp lệ, không backfill reviewer giả. Dùng lock pessimistic trên property trong transaction cho quyết định để tránh cần version column; lặp quyết định không sửa reason/audit đã chốt. Outbox bảng riêng: id, property_id, event_type, event_key unique, recipient snapshot lấy từ account, payload snapshot phục vụ nội dung sau commit, state, attempts, next_attempt_at, claimed_at/lease, last_error, created_at/sent_at; index (state,next_attempt_at), claim CAS/lease chống worker gửi đồng thời, bounded retry/backoff. Khóa event tiếp nhận theo propertyId+received, review theo propertyId+decision vì contract không resubmit; nếu tương lai mở resubmit phải thêm transition version. Transaction ghi property và outbox cùng lúc; worker chỉ claim bản ghi đã commit. SMTP không bảo đảm exactly-once khi process chết sau send trước mark-sent; unique key chống tạo event trùng nhưng cần ghi giới hạn này, dùng provider idempotency nếu có. Rollback drop outbox rồi cột mới, chỉ chạy sau rollback app và xử lý/preserve pending events, không apply DB live. MySQL DDL có implicit commit nên deployment/rollback phải coi là thao tác riêng, đánh giá dialect nếu dùng prod PostgreSQL driver config. Không sao chép secret/payload nhạy cảm vào log.
Các nội dung này là đề xuất khảo sát cho Dispatch implementation tiếp theo; task hiện tại không stage/commit hay sửa mã.
