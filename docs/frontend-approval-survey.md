# Khảo sát Frontend luồng xét duyệt tin

Ngày khảo sát: 23/10/2026. Vai trò: Frontend Worker; chỉ khảo sát, không sửa mã nghiệp vụ.

## 1. Workspace, quy tắc và phạm vi

- Cwd: `C:/Users/admin/orca/workspaces/RealEstateMobile-Project/frontend`.
- Branch: `NhatTruong1905/frontend`; HEAD: `ccb2700aa235e2648036679fb5384027d1c4c7da`.
- Trước khảo sát: `?? AGENTS.md`, `?? docs/agent-rules/`; không có tracked change. Không commit/copy rules, không chuyển branch, không merge.
- Đã đọc đầy đủ UTF8 `AGENTS.md` và `docs/agent-rules/FRONTEND_RULES.md` ngay tại worktree; không cần fallback D:.
- Tóm tắt quy tắc: dùng trạng thái/backend contract thật; tái sử dụng màn hình/service; lý do từ chối bắt buộc và trim; cập nhật UI sau API thành công và refetch; không tự gửi email hoặc suy diễn delivery; chỉ triển khai sau Manager chốt contract. Task hiện tại chỉ cho phép tạo báo cáo này, chưa commit hay triển khai.
- Đã xác minh Orca bằng `skills get orchestration`, `orchestration check` và gửi status thành công. Đã nhận chỉ đạo bổ sung của Manager: FE sở hữu UI Thymeleaf trong `real-estate-backend/src/main/resources/templates/property/` và JS liên quan; dùng Staff UI hiện có, không tạo Staff React/Flutter trùng lặp. Backend Java/security/database không khảo sát sâu, không sửa.
- Contract sẽ được Manager chia sẻ tại `D:/RealEstateMobile-Project/docs/approval-api-contract.md`; chưa dùng contract chưa chốt làm căn cứ triển khai.

## 2. Stack và điểm tái sử dụng

| Bề mặt | Hiện trạng | File chính |
|---|---|---|
| Web người đăng | React 19, TypeScript, Vite 8, React Router 7; state hook cục bộ; CSS riêng, lucide-react | `real_estate_frontend-web/package.json`, `src/App.tsx`, `src/styles/`, `src/layouts/SellerLayout.tsx` |
| Mobile người đăng | Flutter Material 3, Dart SDK constraint ^3.12.2; StatefulWidget/setState, Navigator/MaterialPageRoute và IndexedStack | `real_estate_frontend-mobile/pubspec.yaml`, `lib/main.dart`, `lib/screens/MainScreen.dart` |
| Staff/admin | Thymeleaf, Bootstrap classes/modal, TomSelect, fetch JS inline; form quản lý tin có sẵn | `real-estate-backend/src/main/resources/templates/property/edit.html`, `list.html` |

Web route hiện có `/seller/overview`, `/seller/properties`, `/seller/post`. `ProtectedRoute.tsx` chỉ kiểm tra có token localStorage; chưa kiểm tra quyền Staff. Không có Staff route/service ở React hoặc Flutter. Mobile chuyển seller mode khi có `jwt_token`, không phải kiểm quyền Staff; `UserDTO.dart` không giữ role. Web `UserProfile` có `roleCode?` nhưng guard hiện chưa dùng.

## 3. Mapping trạng thái quan sát được

Đây là mapping từ client/template, **không phải xác nhận enum wire/backend hay response runtime**. Trong phạm vi FE không gọi API thật và không suy ra enum từ Java; Backend/Manager cần xác nhận serialization chính thức.

| Giá trị quan sát | Nơi dùng | Hiển thị hiện tại / gap |
|---|---|---|
| `Đang mở bán` | Thymeleaf `list.html`; mobile so sánh lowercase | Admin badge ĐANG MỞ BÁN; mobile Đang hiển thị |
| `Chờ duyệt` | Thymeleaf; mobile | Admin CHỜ DUYỆT; mobile Chờ duyệt |
| `Từ chối` | Thymeleaf; mobile | Admin TỪ CHỐI; mobile Từ chối nhưng đưa vào tab Đã xóa |
| `Đã xóa` | Thymeleaf; mobile | Xóa mềm; không được đồng nhất với từ chối |
| `PUBLISHED`, `PENDING` | `real_estate_frontend-web/src/data/mockProperties.ts:154` | Mock web, không chứng minh enum backend |
| `published`, `pending`, `rejected`, `deleted`, `đang hiển thị`, `đã ẩn` | Alias mobile qua toLowerCase | Logic tương thích tự đoán, cần thu hẹp theo contract |

Mobile `SellerProperties.dart` lọc trạng thái; `seller_properties_components.dart` render badge. Null status mặc định nhãn xanh “Đang hiển thị”, có nguy cơ thông tin sai. Rejected đang bị xử lý như deleted cả trong chặn xóa. Web `SellerPropertyRow.tsx` in nguyên `property.status || 'Chưa rõ'`, chưa có nhãn tiếng Việt chuẩn. Chưa có bằng chứng client xử lý `APPROVED`.

## 4. API hiện FE đang gọi / kỳ vọng

Đường dẫn dưới đây tương đối với base `/api`, trừ admin. Đây là bằng chứng từ source FE, không thay thế contract phía server.

| Method / endpoint | Auth client | Payload | Response client kỳ vọng |
|---|---|---|---|
| POST `/auth/login` | Không yêu cầu token; web tự gắn token cũ nếu có | JSON `{username,password}` | `{token}`; mobile chỉ nhận 200 |
| GET `/secure/profile` | Bearer JWT | Không | `{data: UserProfile}`; mobile lưu `user_profile` |
| GET `/properties` | Mobile không Bearer; web tự gắn nếu có | Query tìm kiếm/phân trang | `{message,data:{content,currentPage,totalItems,totalPages}}` |
| GET `/secure/properties` | Bearer JWT | Không | `{data: Property[]}`; tin của tôi |
| GET `/secure/properties/{id}` | Web gọi khi có token; mobile gắn token nếu có | Không | `{data: Property}` |
| POST `/secure/properties` | Bearer JWT; mới chỉ mobile triển khai | Multipart text fields từ `PropertyDTO.toFields()`, file lặp key `files`, tối đa 5 file mới | Mobile chỉ coi HTTP 200 là thành công, lấy `responseData.data` |
| DELETE `/secure/properties/{id}` | Bearer JWT; mobile | Không | Mobile chỉ kiểm 200, không đọc body |
| POST `/admin/api/properties` | Same-origin session dự kiến; template gửi X-CSRF-TOKEN từ form | JSON Object.fromEntries(FormData), bỏ `_csrf`; có `id`, `status` và các trường form | Khi response.ok đọc JSON `message`, alert và redirect list; lỗi `message` hoặc map field-error |

Public detail web chưa có endpoint public riêng: `propertyApi.getById()` dùng secure detail nếu đăng nhập, còn khách tải `/properties?page=1&limit=200` rồi find ID. Không có filter visibility ở client; cần backend bảo vệ public list/detail. Seller row web và mobile không có link xem public cho tin chờ/từ chối, hiện phù hợp giới hạn này.

Search DTO mobile (`PropertyRequestDTO.dart`) hỗ trợ `title,fromPrice,toPrice,area,address,districtId,wardId,floorCount,bedroomCount,bathroomCount,direction,legal,staffId,categoryId,typeId,statusProperty,page,limit`. Có tham số không đồng nghĩa backend hiện hỗ trợ đầy đủ.

Client web `src/services/api/core/http.ts`: base cố định `http://localhost:8080/api`, thêm Bearer, bỏ Content-Type tự động khi FormData. Parse JSON/text; lỗi thành Error(message), mất HTTP status và structured field errors; chưa đủ để phân biệt 401/403/404/409/422 trong UI. `VITE_USE_MOCKS === 'true'` fallback khi request lỗi, vẫn gọi API trước; chưa phải mock offline thuần và có thể che lỗi quyền/mạng.

Mobile `AppConfig.dart`: dev `http://10.0.2.2:8080/api`, release remote Railway; JWT trong SharedPreferences. `APIPropertyMixin.dart` bắt lỗi read và trả []/null nên phân biệt lỗi mạng/auth với danh sách rỗng chưa được. Save trả success/message generic, chưa có field error/status typed. Không gọi endpoint nào trong survey.

## 5. Schema, form, rejection reason và resubmit

Mobile model `lib/dto/PropertyDTO.dart` có: id/userId/typeId/categoryId, title/description, address/city/wardId/addressDetail, price/area, floorCount/bedroomCount/bathroomCount, direction/legal/status, images/image và thông tin người đăng. `toFields()` serialize các field khác null, trim chuỗi, ảnh cũ thành `images[i]`. Không có created date, rejection reason, moderation metadata hoặc email delivery status. Web `src/types.ts` có Property tương tự nhưng không có wardId; có typeName/categoryName/latitude/longitude. Cả hai không parse lý do thực tế, nên dù server trả field mới cũng chưa hiển thị.

Mobile `PostProperty.dart` + `post_property_view.dart` đã có form tạo/sửa, nạp detail, ảnh cũ/mới/camera, giới hạn tổng 5 ảnh, title/address trim-required, price/area >0, loading và disable submit khi đang gửi. `_submitForm` chưa có early guard `_isLoading`; chỉ disable button. Các field số phòng/tầng parse int nhưng chưa validation âm hoặc sai số. Category ID 1..5/type ID mặc định và legal/direction hardcode, cần xác nhận danh mục. Mô tả không bắt buộc hiện tại. Không nên suy ra toàn bộ validation backend từ UI.

Mobile sửa từ `SellerProperties` mở cùng PostPropertyScreen và truyền id. POST multipart có id, giữ images cũ còn chọn; không gửi status trong flow `_submitForm`. **Không có endpoint/action resubmit riêng, không có logic client reset pending/rejection reason**; backend có tự đặt lại trạng thái, xoá lý do, gửi lại email hay không chưa xác định. Sửa/xóa đang được render cho mọi trạng thái, kể cả rejected. Sau sửa thành công quay lại trả true và danh sách refetch. Tạo từ MainScreen trả true rồi setState; chưa đảm bảo SellerProperties initState chạy lại nếu key/widget giữ nguyên, cần test refresh sau tạo.

Mobile thành công hiện nói “Đăng tin bất động sản thành công!” hoặc “Cập nhật tin đăng thành công!”, chưa có nội dung chờ duyệt/chưa công khai/email theo rules. Chưa dùng response status để xác nhận trạng thái.

Web `PostPropertyScreen.tsx` chỉ preventDefault, không có controlled state, API create/upload, loading/error/success. Có HTML required/min nhưng category/type label tĩnh chưa map ID; đây là gap implementation lớn hơn mobile. Web danh sách tin chỉ useEffect một lần, không catch/retry/loading riêng, không refetch action; undefined items bị hiện như rỗng. Seller row thiếu ngày đăng, lý do và nhãn trạng thái chuẩn.

## 6. Staff UI hiện có (scope Manager bổ sung)

- `templates/property/list.html`: GET `/admin/properties-list`, filter tiêu đề/địa chỉ/quận/phường và các field khác, pagination, trạng thái badge tiếng Việt, nút sửa/xóa/giao việc. Chỉ nút giao việc có `sec:authorize="hasRole('ADMIN')"` quan sát tại template; quyền route/mutation thật cần Backend xác nhận. Có modal xem full text và giao nhân viên, chưa có dialog từ chối nhập lý do hoặc approve confirm riêng.
- `edit.html`: form JSON POST `/admin/api/properties` dùng danh mục `${users}`, `${categories}`, `${wards}`, `${types}` từ server. Status dropdown render `${status}` dùng `${st.status}`; đang cho sửa chung status, không có reason required khi từ chối, không có giới hạn ký tự/notification copy. Chưa có gallery ảnh trong form đã đọc.
- JS inline có map field error, generic network catch, redirect/reload sau success, nhưng không loading/disable chống submit lặp và không branch lỗi concurrency 409. Cần thêm reason form/approve confirm trong UI hiện có theo contract, tránh đường cập nhật status chung bỏ qua validation reason.
- Auth admin dùng request same-origin và token CSRF đọc từ form; chính sách session/role/assignment phải do Backend xác nhận độc lập. Không đưa JWT của mobile vào admin UI.

## 7. Email

Không có luồng gửi email xét duyệt trực tiếp trong source FE khảo sát; không gửi email thật. `userEmail` là dữ liệu liên hệ, không phải trạng thái delivery. Mobile forgot-password có OTP email nhưng thuộc luồng auth khác, không tái sử dụng để gửi moderation email. Cần copy sau tiếp nhận/phê duyệt/từ chối nói hệ thống sẽ xử lý thông báo, không khẳng định email delivered nếu chỉ enqueue.

## 8. Test/build evidence và giới hạn

Đã thử lệnh tại đúng từng frontend, không cài dependency hay gọi backend/email:

| Lệnh | Kết quả |
|---|---|
| Web `npm run build` | Exit 1: `'tsc' is not recognized`; `node_modules` chưa có |
| Web `npm run lint` | Exit 1: `'oxlint' is not recognized`; dependency chưa có |
| Mobile `flutter test --no-pub` | Exit 1: cannot run without dependency on package:flutter_test/package:test; pubspec đã khai báo flutter_test nhưng `.dart_tool/package_config.json` chưa tồn tại trước lệnh, dependency chưa resolve |

Flutter/Dart có trên PATH `D:/flutter_windows_3.47.7-stable/flutter/bin`; Node/npm có ở `D:/nodejs`. Chưa chạy pub get/npm ci vì nhiệm vụ khảo sát, không cần thay lock/cache để đọc code. Không coi các lệnh trên là test pass hoặc bằng chứng lỗi source. Chưa chạy mobile build/analyze do dependency chưa sẵn sàng; cần resolve dependency và rerun ở task implementation.

Web package chỉ có dev/build/lint/preview, không test script/framework trong package.json. Mobile có `test/widget_test.dart` smoke MaterialApp/Scaffold, không coverage nghiệp vụ xét duyệt. Chưa có FE fixture/test approve/reject/reason/resubmit/auth/race/network; workflow tracked hiện thấy `.github/workflows/backend-ci-cd.yml`, chưa có workflow frontend riêng.

Các test cần thêm khi triển khai: schema/form/double-submit; tạo thành công đúng pending; mapping đầy đủ và ngày/reason; reason rỗng/whitespace/max length/server validation; approve confirm; mutation failure không báo thành công; refetch và stale conflict; unauthorized/forbidden/not found; edit/resubmit theo contract; public visibility; mock không chạm email provider.

## 9. Các điểm Manager/Backend cần chốt trước implementation

1. Wire status thật: response là chuỗi tiếng Việt hay enum code; đủ các trạng thái bán/ẩn/xóa; mapping pending/approved/rejected không suy diễn từ mock.
2. Staff thao tác qua admin session+CSRF nào, endpoint/method approve/reject thực tế; quyền ADMIN/STAFF và assignment scope; payload/response/status code.
3. Tên field reason, required trim, max length, Unicode validation, field-error shape; response reason/date trên mine/detail và quyền xem.
4. Tạo/sửa vẫn POST multipart: mã 200/201, schema required, danh mục ID, giới hạn ảnh/kích thước/MIME; source danh mục cho web.
5. Resubmit: sửa rejected có tự pending không, lúc nào reset reason/email; sửa approved có cần duyệt lại không; cách xử lý deleted và conflict/version.
6. Public visibility trên backend và date field/timezone; trạng thái email chỉ enqueue hay có delivery status.

## 10. File thay đổi và bàn giao

Chỉ thêm `docs/frontend-approval-survey.md`. Không sửa UI/service/backend, không commit, không merge và không email thật. Báo cáo được chia sẻ bằng absolute path `C:/Users/admin/orca/workspaces/RealEstateMobile-Project/frontend/docs/frontend-approval-survey.md`; worktree khác không tự có file này. Chờ task implementation riêng sau khi Manager chốt contract.

## 11. Đối chiếu DRAFT Manager vừa chia sẻ

Đã đọc UTF8 `D:/RealEstateMobile-Project/docs/approval-api-contract.md` sau khi có thông báo cuối survey; đây vẫn là DRAFT, chưa implementation. Theo bằng chứng Manager cung cấp, wire status chính thức là `Chờ duyệt` / `Đang mở bán` / `Từ chối` / `Đã xóa`, tương ứng enum Java PENDING/PUBLISHED/REJECTED/DELETED. Mapping template phù hợp; mock web PUBLISHED/PENDING không phù hợp wire và alias mobile cần chuẩn hóa, tách rejected/deleted.

- Staff giữ POST JSON `/admin/api/properties`, session+CSRF, form hiện có + id/status/rejectionReason, không cần endpoint approve/reject mới. Frontend cần confirm approve và form reason bắt buộc khi từ chối; không tạo Staff route mới.
- Reason DRAFT tên `rejectionReason`, trim 1..1000; lỗi 422 `{message,detail:'VALIDATION_ERROR',data:{rejectionReason:'...'}}`, tương thích legacy 400/list. Web request hiện làm mất data/status, admin form hiện chỉ map top-level field, mobile hiện chỉ raw message: cả ba cần điều chỉnh đọc structured errors khi implementation.
- Tạo trả DTO id/status thật: Manager báo response multipart hiện chưa có id/status thật, BE sẽ sửa. Mobile không dùng DTO trong success, web chưa create nên cần tích hợp sau BE sửa. Không tự kết luận response hiện tại đã đáp ứng DRAFT.
- DRAFT có `wardId`, `legal`, danh mục ID: web model/form thiếu wardId và mobile không chọn ward trong form, cần FINAL xác nhận required/optional và address parser; đây là mismatch schema cần giải quyết trước tích hợp. Không tự thêm endpoint danh mục khi chưa chốt.
- Admin list DRAFT dùng filter `status=Chờ duyệt` và page,size; mobile public search lại dùng `statusProperty`, page,limit. Cần giữ phân biệt contract admin/public, không copy query giữa hai bề mặt.
- Owner detail/assignment auth, concurrency 409 và email outbox là bảo đảm phía BE trong DRAFT, survey FE chưa kiểm runtime. UI phải refetch khi thành công và xử lý 409, không optimistic đổi trạng thái.
- Theo chỉ đạo mới, không tạo resubmit/action gửi duyệt lại; giữ hành vi edit hiện tại đến khi Backend xác minh. Dependency install được Manager cho phép cho implementation sau, survey không tự cài.
