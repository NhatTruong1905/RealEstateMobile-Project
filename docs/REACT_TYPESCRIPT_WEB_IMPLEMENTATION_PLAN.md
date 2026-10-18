# Kế hoạch xây dựng giao diện web bằng React và TypeScript

Ngày lập: 18/10/2026.

Trạng thái: kế hoạch triển khai; chưa xác nhận frontend web đã được xây dựng.

## 1. Mục tiêu và quyết định đã thống nhất

Xây dựng một frontend web riêng cho hệ thống bất động sản bằng **ReactJS + TypeScript**, dùng chung Spring Boot backend và dịch vụ AI với ứng dụng Flutter mobile.

- Người dùng đã chọn React và TypeScript. Không chuyển hướng sang Flutter Web hoặc JavaScript thuần.
- Thiết kế cho trải nghiệm trình duyệt trên desktop, tablet và điện thoại.
- Dùng UI/UX Pro Max để định hình trải nghiệm, cấu trúc thông tin và design system.
- Dùng Impeccable để critique (đánh giá, chỉ ra vấn đề có lý do) và polish (tinh chỉnh, hoàn thiện giao diện).
- Tận dụng nghiệp vụ và API hiện có, viết lại giao diện bằng React; không chuyển nguyên bố cục điện thoại sang màn hình lớn.
- Ngôn ngữ giao diện mặc định là tiếng Việt; định dạng giá theo VND và diện tích theo m².

Đây là tài liệu bàn giao cho agent triển khai về sau. Việc tạo tài liệu này không đồng nghĩa đã cài skill, tạo ứng dụng hoặc triển khai website.

## 2. Cấu trúc repository và nguồn cần đọc

Tại thời điểm lập kế hoạch, repository có các thư mục:

```text
real_estate_frontend-mobile/  # Flutter hiện có
real_estate_frontend-web/     # Nơi triển khai React + TypeScript
real-estate-backend/          # Spring Boot, API, xác thực và chat
real-estate-ai/               # FastAPI, chatbot RAG
docs/
```

Thư mục web hiện chưa có mã nguồn được liệt kê khi khảo sát. Agent phải kiểm tra lại hiện trạng trước khi khởi tạo, tránh ghi đè công việc mới. Một số tài liệu cũ còn ghi `real_estate_frontend`; đường dẫn đó cần đối chiếu với thư mục mobile hiện tại.

Đọc tối thiểu:

1. `AGENTS.md` áp dụng cho thư mục làm việc, nếu có.
2. `docs/UI_UX_PROMAX_VS_IMPECCABLE.md` để hiểu định hướng thiết kế. Đây là tài liệu so sánh, không phải `SKILL.md` của hai skill.
3. `real_estate_frontend-mobile/lib/screens/` và `layout/` để lập danh sách chức năng, trạng thái và luồng người dùng.
4. `real_estate_frontend-mobile/lib/dto/`, `mixin/api/`, `services/` và `config/AppConfig.dart` để hiểu dữ liệu và kết nối hiện có.
5. Controller, DTO, cấu hình security và WebSocket của Spring Boot để xác minh hợp đồng backend.
6. `real-estate-ai/api/routes.py`, schemas và `main.py` để xác minh API AI, cấu trúc streaming và khả năng truy cập từ trình duyệt.

Giữ nguyên những thay đổi đang có của người dùng. Không khôi phục thư mục cũ, đổi tên thư mục hoặc sửa ứng dụng mobile chỉ để phù hợp với kế hoạch này.

## 3. Quy trình sử dụng UI/UX Pro Max và Impeccable

### 3.1. Kiểm tra skill trước khi áp dụng

- Tìm đúng skill đã cài và đọc `SKILL.md` thực tế; kiểm tra nguồn, phạm vi và hướng dẫn liên quan.
- Không mặc định hai skill là sản phẩm chính thức của OpenAI hoặc có cùng lệnh ở mọi nguồn phát hành.
- Không tự bịa lệnh như `/critique` hay `/polish` nếu tài liệu skill không có.
- Nếu thiếu skill được yêu cầu, báo rõ skill nào thiếu và nguồn cần xác định/cài đặt. Có thể tiếp tục khảo sát repository và lập hợp đồng API, nhưng không tuyên bố đã áp dụng skill khi chưa đọc được.
- Tài liệu này không thay thế chỉ dẫn của skill. Khi có xung đột, tuân thủ chỉ dẫn cấp cao hơn và yêu cầu mới nhất của người dùng.

### 3.2. UI/UX Pro Max: định hình trước khi triển khai

Phân tích hai nhóm chính: người tìm bất động sản và người bán/môi giới.

Đầu ra cần có:

- Luồng tìm kiếm → lọc → xem chi tiết → lưu tin → liên hệ/chat.
- Luồng đăng nhập → đăng/sửa tin → quản lý tin → quản lý khách hàng/chat.
- Sơ đồ trang và thứ tự ưu tiên thông tin từng trang.
- Định hướng hình ảnh, màu sắc, typography, spacing, breakpoint và component dùng chung.
- Trạng thái loading, empty, error, disabled, success và chưa đăng nhập.
- Bản thiết kế hoặc triển khai mẫu Trang chủ, Danh sách và Chi tiết để kiểm tra tính nhất quán trước khi mở rộng.

### 3.3. Impeccable: critique rồi polish

Sau khi mỗi nhóm trang đã có chức năng:

1. Critique giao diện đã render: ghi vấn đề, tác động đến người dùng, mức ưu tiên và cách sửa.
2. Polish theo vấn đề đã ghi: phân cấp chữ, khoảng trắng, căn chỉnh, ảnh, tương phản, CTA và trạng thái tương tác.
3. Kiểm tra lại trên desktop và điện thoại, bao gồm bàn phím và trạng thái lỗi.
4. Ghi nhận thay đổi và minh chứng trước/sau khi có điều kiện.

Không chỉ thay màu, bo góc và thêm hiệu ứng. Nếu luồng tác vụ sai, phải sửa cấu trúc trước khi tinh chỉnh hình thức. Không tự mở rộng nghiệp vụ hoặc thay hợp đồng API trong vòng polish.

## 4. Stack và tổ chức mã đề xuất

Mặc định triển khai **React + TypeScript + Vite**, React Router cho điều hướng và CSS có token dùng chung, có thể dùng CSS Modules. Chọn phiên bản tương thích tại thời điểm triển khai và lưu lockfile. Không tự thêm nhiều thư viện UI chồng chéo.

Vite là lựa chọn mặc định cho phạm vi ứng dụng web hiện tại. Nếu sau này có yêu cầu SEO mạnh cho từng tin đăng, cần đánh giá riêng phương án render phía server/prerender với React trước khi đổi kiến trúc; không coi SPA đã mặc nhiên đáp ứng đầy đủ SEO.

```text
real_estate_frontend-web/
  src/
    app/              # Router, providers, cấu hình khởi tạo
    layouts/          # PublicLayout, SellerLayout
    pages/            # Trang gắn với route
    features/
      auth/
      properties/
      favorites/
      account/
      seller/
      chat/
      ai-assistant/
    components/       # Button, Input, Dialog, Pagination, trạng thái dùng chung
    services/         # HTTP client và cấu hình kết nối
    types/            # Kiểu dùng chung và hợp đồng API
    styles/           # Tokens, reset, typography, global styles
  .env.example
  README.md
```

Nguyên tắc:

- Bật TypeScript `strict`; không dùng `any` hoặc ép kiểu để che lỗi.
- Tách việc gọi API, xử lý dữ liệu và hiển thị; tránh một component chứa toàn bộ màn hình lẫn nghiệp vụ.
- Dữ liệu từ API vẫn cần kiểm tra/chuyển đổi ở ranh giới phù hợp; TypeScript không tự xác thực JSON khi chạy.
- Phân biệt kiểu phản hồi backend với mô hình dùng cho giao diện nếu cấu trúc khác nhau.
- Không suy đoán rằng trường luôn tồn tại: DTO mobile hiện có nhiều trường nullable.
- Bắt đầu với state cục bộ/context phù hợp; chỉ thêm công cụ quản lý state/cache khi có nhu cầu cụ thể.

## 5. Phạm vi trang và điều hướng

Các route dưới đây là đề xuất cho frontend, không phải khẳng định endpoint backend.

| Route | Mục tiêu | Bố cục desktop |
|---|---|---|
| `/` | Trang chủ, tìm kiếm và khám phá tin | Header, tìm kiếm nổi bật, lưới tin |
| `/properties` | Tìm kiếm, lọc, sắp xếp, phân trang | Bộ lọc trái, kết quả phải |
| `/properties/:id` | Chi tiết bất động sản | Gallery, thông tin chính, khu vực liên hệ |
| `/login`, `/register` | Xác thực | Form dễ đọc, lỗi theo trường |
| `/forgot-password` | Khôi phục tài khoản theo API hiện có | Các bước rõ ràng |
| `/saved` | Tin đã lưu | Lưới tin, trạng thái trống |
| `/account` | Hồ sơ, ảnh đại diện và bảo mật | Điều hướng tài khoản, form |
| `/seller/overview` | Tổng quan người bán | Sidebar và chỉ số có dữ liệu thật |
| `/seller/properties` | Quản lý tin | Danh sách/bảng phù hợp nội dung |
| `/seller/post` | Đăng tin | Form nhóm theo nội dung, upload ảnh |
| `/seller/properties/:id/edit` | Sửa tin nếu API hỗ trợ | Tái sử dụng form đăng tin |
| `/seller/customers` | Khách hàng theo nghiệp vụ hiện có | Danh sách và thông tin liên quan |
| `/messages` | Chat giữa người mua và người bán | Danh sách hội thoại và nội dung chat |
| `/faq`, `/terms`, `/privacy` | Nội dung hỗ trợ và chính sách | Văn bản dễ đọc |

Không tạo số liệu giả cho dashboard hoặc nút chức năng chưa hoạt động mà không ghi rõ. Không xây lại trang quản trị Thymeleaf trong phạm vi mặc định.

Yêu cầu điều hướng:

- Có trang 404 và trạng thái tin không tồn tại/không truy cập được.
- Refresh hoặc mở trực tiếp URL chi tiết phải hoạt động.
- Từ khóa, bộ lọc, thứ tự và trang kết quả lưu trong query parameters; Back/Forward khôi phục đúng trạng thái.
- Route cần đăng nhập phải xử lý khôi phục phiên trước khi chuyển hướng và giữ đường dẫn quay lại.
- Phân quyền phía giao diện chỉ hỗ trợ trải nghiệm; backend vẫn kiểm tra quyền và quyền sở hữu.

## 6. Định hướng thiết kế

Mục tiêu hình ảnh: đáng tin cậy, dễ đọc, ưu tiên ảnh và thông tin bất động sản tại Việt Nam.

- Dùng nền trung tính, một màu thương hiệu chính và màu trạng thái có ý nghĩa.
- Tham khảo thương hiệu hiện tại; xác định một bảng màu thống nhất thay vì bê mọi màu từ mobile.
- Font hỗ trợ tiếng Việt đầy đủ; giới hạn số font và mức độ đậm.
- Chuẩn hóa token cho màu, chữ, khoảng cách, bo góc, bóng đổ và chuyển động.
- Có thể bắt đầu spacing scale 4/8/12/16/24/32/48 px, sau đó hiệu chỉnh theo thiết kế.
- Thẻ tin ưu tiên ảnh → giá → tiêu đề → vị trí → diện tích/thông số; không nhồi badge và icon.
- Phân biệt rõ CTA chính và phụ; không dùng quá nhiều gradient, shadow hoặc animation trang trí.
- Dữ liệu chưa có phải hiển thị phù hợp, không tự biến thành giá 0 hoặc thông tin pháp lý chắc chắn.
- Trợ lý AI phải tách biệt với chat người bán và phân biệt câu trả lời AI với dữ liệu xác thực.

Responsive dựa trên chiều rộng khả dụng. Mốc khởi đầu: dưới 768 px, 768–1199 px và từ 1200 px; điều chỉnh khi nội dung cần, không coi đây là chuẩn bắt buộc.

- Desktop: header đầy đủ, nội dung có max-width, lưới tin nhiều cột, sidebar cho người bán.
- Tablet: giảm số cột, thu gọn điều hướng khi cần.
- Điện thoại: một cột; bộ lọc dạng drawer/dialog; menu có thể thu gọn; CTA không che nội dung.
- Kiểm tra tối thiểu ở 375, 768, 1280 và 1440 px; không có cuộn ngang ngoài ý muốn.
- Hỗ trợ bàn phím, focus nhìn thấy rõ, label cho form, tên truy cập cho nút chỉ có icon và quản lý focus khi mở/đóng dialog.
- Đảm bảo tương phản phù hợp WCAG AA, không truyền đạt trạng thái chỉ bằng màu; hỗ trợ reduced motion.

## 7. Tích hợp backend và AI

### 7.1. Lập hợp đồng trước khi code tính năng

Đối chiếu Flutter với controller/DTO backend. Lập bảng endpoint gồm method, URL, xác thực, tham số, request/response, lỗi và phân trang. Xác minh chỉ số trang bắt đầu từ 0 hay 1, đơn vị giá, trạng thái tin và tên trường upload.

Không mặc định mọi API có cùng wrapper `data`, cùng tên token hoặc cùng quy tắc lỗi. Không bịa endpoint để giao diện có vẻ hoàn chỉnh.

### 7.2. Biến môi trường

Ví dụ cho Vite khi phát triển trên máy:

```dotenv
VITE_API_BASE_URL=http://localhost:8080/api
VITE_WS_URL=ws://localhost:8080/ws
VITE_AI_BASE_URL=http://localhost:8000/api
```

Đưa ví dụ vào `.env.example`, xác minh cổng thực tế và tránh ghép trùng `/api`. Không dùng `10.0.2.2` của Android Emulator cho trình duyệt. Biến `VITE_*` được đưa vào frontend nên không chứa mật khẩu, khóa AI hoặc bí mật backend. Production dùng địa chỉ HTTPS/WSS phù hợp và cấu hình origin tương ứng.

### 7.3. Các điểm cần xử lý

- **Xác thực:** kiểm tra JWT hiện có, chiến lược lưu phiên, hết hạn, logout và lỗi 401/403. Không tự thêm cơ chế refresh token nếu backend chưa hỗ trợ. Google/Facebook cần cấu hình dành cho web; không giả định cấu hình mobile dùng được ngay.
- **Ảnh:** dùng `File`/`Blob` của trình duyệt và `FormData`; giữ đúng field multipart, giới hạn dung lượng, số ảnh và định dạng mà backend hỗ trợ. Không tự đặt header multipart làm mất boundary. Thu hồi object URL khi không dùng.
- **Chat:** backend đã có cấu hình STOMP, endpoint `/ws`, prefix ứng dụng `/app` và broker `/topic`, `/queue`, `/user`. Đọc `ChatService.dart` và backend để xác định destination, payload và cách xác thực chính xác. Quản lý reconnect, unsubscribe, tránh tin trùng và đóng kết nối khi logout.
- **AI:** hiện có route POST `/api/chat-rag` và `/api/chat-rag/stream`; đọc implementation để xác định định dạng stream, không mặc định là SSE. Hỗ trợ hủy request, lỗi giữa stream và hiển thị phản hồi đang sinh.
- **CORS:** Spring Boot có cấu hình CORS nhưng vẫn cần kiểm tra origin thực tế và WebSocket. `real-estate-ai/main.py` chưa thấy đăng ký CORS middleware lúc khảo sát; cần kiểm tra proxy/cấu hình đầy đủ trước khi gọi AI trực tiếp từ trình duyệt. Không mở rộng CORS toàn hệ thống như một cách sửa mặc định.
- **Dữ liệu:** xử lý ảnh lỗi, tin bị gỡ, danh sách trống, phản hồi chậm, gửi form hai lần và kết quả tìm kiếm cũ trả về sau truy vấn mới.

## 8. Lộ trình triển khai và đầu ra từng giai đoạn

### Giai đoạn 1 — Khảo sát và định hình

- Kiểm tra mã hiện có, skill và API; liệt kê chức năng đã hỗ trợ/chưa hỗ trợ.
- Áp dụng UI/UX Pro Max; xác định sitemap, user flow, tokens và bố cục mẫu.
- Ghi quyết định thiết kế cùng các điểm backend còn chưa rõ; không hỏi lại lựa chọn React/TypeScript đã thống nhất.

Đầu ra: phạm vi, hợp đồng API, design direction và kế hoạch theo trang.

### Giai đoạn 2 — Nền tảng React

- Khởi tạo vào `real_estate_frontend-web` nếu chưa có; cấu hình TypeScript strict, router, lint, styles và env.
- Xây PublicLayout, SellerLayout, component cơ bản và các trạng thái dùng chung.
- Thiết lập HTTP client, xử lý lỗi và khôi phục phiên theo hợp đồng thật.

Đầu ra: ứng dụng chạy được, route và khung responsive hoạt động.

### Giai đoạn 3 — Luồng người mua

- Xây Trang chủ → Danh sách → Chi tiết bằng API thật.
- Hoàn thiện bộ lọc, phân trang, URL, gallery, thông tin và điều hướng liên hệ.
- Critique và polish nhóm trang này trước khi nhân rộng thiết kế.

Đầu ra: luồng tìm bất động sản hoàn chỉnh; CTA phụ thuộc chat/xác thực dẫn đến trạng thái phù hợp, không có nút chết.

### Giai đoạn 4 — Tài khoản và người bán

- Hoàn thiện đăng ký, đăng nhập, khôi phục tài khoản và tin đã lưu.
- Xây hồ sơ, đổi mật khẩu, tổng quan người bán, quản lý tin và form đăng/sửa theo API thực tế.
- Kiểm tra quyền sở hữu, upload ảnh, validation và xử lý lỗi.

Đầu ra: người dùng có thể hoàn thành các nghiệp vụ được backend hỗ trợ.

### Giai đoạn 5 — Chat và trợ lý AI

- Kết nối chat thực, danh sách hội thoại và trạng thái chưa đọc theo nghiệp vụ hiện có.
- Kết nối AI, streaming, hủy yêu cầu và lịch sử nếu API hỗ trợ.
- Kiểm tra hết phiên, mất kết nối, reconnect và phản hồi lỗi.

Đầu ra: hai loại hội thoại hoạt động rõ ràng, không lẫn dữ liệu hoặc trạng thái.

### Giai đoạn 6 — Hoàn thiện và bàn giao

- Áp dụng Impeccable critique/polish trên giao diện render thực tế, kiểm tra lại toàn bộ luồng.
- Kiểm tra responsive, accessibility, hiệu năng và lỗi console.
- Hoàn thiện title/meta cơ bản, favicon, trang 404 và fallback URL trên hosting.
- Ghi README: cài đặt, chạy, build, biến môi trường, kiểm thử và giới hạn còn lại.

Đầu ra: bản web có thể review cùng hướng dẫn chạy; deploy công khai thực hiện theo yêu cầu/ủy quyền của người dùng.

## 9. Tiêu chí nghiệm thu

- React + TypeScript, strict; build, kiểm tra kiểu và lint thành công theo scripts của dự án.
- Các luồng trong phạm vi kết nối API thật. Mock chỉ dùng tạm khi phát triển, phải ghi rõ và không âm thầm thay thế tích hợp còn thiếu.
- Trạng thái tải, trống, lỗi, chưa đăng nhập và không có quyền được xử lý.
- Tìm kiếm/lọc/phân trang đồng bộ URL; refresh và Back/Forward hoạt động.
- Đăng nhập/logout, tin đã lưu, đăng/sửa tin và chat không rò trạng thái giữa tài khoản.
- Giao diện hoạt động ở các chiều rộng mục 6, bàn phím dùng được, không có nội dung bị che hoặc cuộn ngang ngoài ý muốn.
- Có kiểm tra trực quan trong trình duyệt; ghi rõ nếu môi trường không cho phép kiểm tra thay vì tuyên bố đã xác minh.
- Kiểm thử có ý nghĩa cho chuyển đổi dữ liệu, xác thực, bộ lọc, quyền và luồng quan trọng; không chỉ kiểm tra component render được.
- Có bằng chứng chạy các bước kiểm tra và danh sách hạn chế/tích hợp chưa hoàn tất; không đánh dấu hoàn thành chỉ vì trang đã đẹp.
- Không có bí mật trong frontend hoặc thay đổi mobile/backend ngoài phạm vi cần thiết đã được giải thích.

## 10. Chỉ dẫn khởi động cho agent đọc tài liệu

Khi người dùng yêu cầu triển khai theo file này:

1. Đọc chỉ dẫn repository và khảo sát lại trạng thái hiện tại; không khởi tạo đè thư mục đã có mã.
2. Đọc skill thực tế và các nguồn trong mục 2; xác minh API trước khi tích hợp.
3. Giữ các quyết định đã thống nhất; tiến hành theo thứ tự giai đoạn 1–6, cập nhật tiến độ và các vấn đề cụ thể.
4. Chọn chi tiết kỹ thuật thường lệ bằng phán đoán phù hợp; chỉ hỏi khi thiếu thông tin ảnh hưởng đáng kể đến phạm vi, nguồn skill, quyền truy cập hoặc quyết định sản phẩm.
5. Nếu một tích hợp bị chặn, tiếp tục phần độc lập có ích và ghi rõ phần chưa xong. Không trình bày mock hoặc ảnh thiết kế như một website hoàn chỉnh.
6. Khi bàn giao, nêu phần đã xây, cách chạy, kết quả kiểm tra, phần còn thiếu và đường dẫn mã/tài liệu liên quan.

Tài liệu này là kế hoạch làm việc có thể cập nhật theo hiện trạng; không phải yêu cầu tự động cài plugin, ghi đè dữ liệu, thay đổi backend diện rộng hoặc xuất bản website.
