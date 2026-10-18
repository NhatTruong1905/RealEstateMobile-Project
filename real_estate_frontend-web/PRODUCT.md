# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- Người mua và người thuê bất động sản tại Việt Nam cần tìm, lọc, so sánh, lưu và liên hệ về tin phù hợp.
- Chủ nhà và người bán cần đăng tin, quản lý tin và theo dõi khách hàng quan tâm.

## Product Purpose

Ứng dụng giúp người dùng khám phá bất động sản, đánh giá thông tin cốt lõi và chuyển sang liên hệ; đồng thời cung cấp các nghiệp vụ đăng và quản lý tin mà backend hiện có hỗ trợ.

## Positioning

Trải nghiệm tập trung vào bất động sản Việt Nam, trình bày ảnh, giá, vị trí và thông số theo thứ tự ra quyết định, với dữ liệu lấy từ API hiện có thay vì số liệu minh họa không được xác thực.

## Operating Context

Người mua thường tìm kiếm nhanh trên điện thoại rồi xem kỹ trên màn hình lớn. Bộ lọc, thứ tự và phân trang cần lưu trên URL để có thể chia sẻ, tải lại và dùng Back/Forward. Người bán làm việc qua khu vực quản lý riêng.

## Capabilities and Constraints

- React 19, TypeScript strict và Vite 8 trong `real_estate_frontend-web`.
- API Spring Boot cung cấp danh sách bất động sản công khai, xác thực JWT, hồ sơ, tin đã lưu và nghiệp vụ tin của người dùng.
- Trang chi tiết hiện dùng endpoint bảo vệ `/api/secure/properties/{id}`; khách chưa đăng nhập cần được dẫn tới đăng nhập và quay lại đúng URL.
- API danh sách dùng trang bắt đầu từ 1 và phản hồi gồm `content`, `currentPage`, `totalItems`, `totalPages` trong `data`.
- Không bịa endpoint, số liệu dashboard, thông tin pháp lý hoặc trạng thái chắc chắn khi API không cung cấp.
- Chat người bán và trợ lý AI là hai luồng riêng; chỉ hiển thị tính năng khi tích hợp tương ứng hoạt động.

## Evidence on Hand

- Kế hoạch triển khai: `../docs/REACT_TYPESCRIPT_WEB_IMPLEMENTATION_PLAN.md`.
- Hợp đồng API hiện có: `../real-estate-backend/src/main/java/com/ndnt/controllers/api/`.
- Ứng dụng Flutter hiện có là nguồn tham chiếu nghiệp vụ trong `../real_estate_frontend-mobile/`.
- Chưa có testimonial, số liệu thị trường hoặc tài sản thương hiệu được xác nhận; giao diện không được tự tạo các tuyên bố đó.

## Product Principles

1. Dữ liệu thật và trạng thái rõ quan trọng hơn vẻ ngoài đầy đặn giả tạo.
2. Ảnh, giá, vị trí và thông số phải hỗ trợ quyết định trong vài giây.
3. Mọi thao tác chính cần dùng được bằng bàn phím, điện thoại và URL trực tiếp.
4. Người mua và người bán có điều hướng rõ ràng, không trộn lẫn nhiệm vụ.
5. Các tích hợp chưa sẵn sàng phải có trạng thái trung thực và đường đi tiếp theo hữu ích.

## Accessibility & Inclusion

Giao diện hướng tới WCAG AA, hỗ trợ bàn phím, focus rõ, label form, tên truy cập cho nút icon, reduced motion và tiếng Việt có dấu đầy đủ.
