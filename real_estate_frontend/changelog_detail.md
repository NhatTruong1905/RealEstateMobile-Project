# NHẬT KÝ THAY ĐỔI CHI TIẾT (CHANGELOG DETAIL)
**Ngày cập nhật**: 29/07/2026
**Dự án**: Real Estate Mobile App (Flutter Frontend & Spring Boot Backend)

---

### 1. Màn Hình Chi Tiết Bất Động Sản (`lib/screens/PropertyDetail.dart`) & Luồng Tương Tác Backend

#### 1.1 Tích hợp API Interaction (`lib/mixin/api/APIInteractionMixin.dart`)
- **Tạo mới `APIInteractionMixin.dart` & `InteractionTypeDTO.dart`**:
  - Tích hợp API `POST /api/secure/interactions` gửi dữ liệu `InteractionDTO` (`propertyId`, `receiverId`, `senderId`, `code`, `message`).
  - Sử dụng trực tiếp mã CODE chuẩn:
    - `'CALL'`: Tương tác gọi điện thoại.
    - `'VIEWING'`: Tương tác đặt lịch hẹn xem nhà.
    - `'MESSAGE'`: Tương tác nhắn tin trao đổi với chủ nhà.
  - Tích hợp API `GET /api/interactions/property/{propertyId}` (hoặc `/api/secure/interactions/property/{propertyId}`) để lấy lịch sử tương tác của người dùng đối với bất động sản hiện tại.

#### 1.2 Tự động kiểm tra & Khóa nút Hẹn xem nhà khi đã tương tác
- Khi mở `PropertyDetailScreen`, ứng dụng tự động kiểm tra xem người dùng hiện tại đã có tương tác đặt lịch xem nhà (`code == 'VIEWING'`) đối với BĐS này chưa.
- Nếu đã đặt lịch: Nút **Hẹn xem nhà** sẽ tự động chuyển sang trạng thái **"Đã đặt lịch xem"** với biểu tượng tick xanh (`Icons.check_circle`) và **bị khóa (disable)** để tránh đặt trùng lặp.

#### 1.3 Luồng Đặt Lịch Xem Nhà Tương Tác (DatePicker & TimePicker)
- Khi bấm nút **Hẹn xem nhà**:
  1. Hiển thị hộp thoại chọn Ngày (`showDatePicker`).
  2. Hiển thị hộp thoại chọn Giờ (`showTimePicker`).
  3. Định dạng chuỗi ngày giờ: `"Lịch hẹn xem nhà: HH:mm - Ngày dd/MM/yyyy"`.
  4. Gán chuỗi ngày giờ này vào trường `message` của DTO và gửi API `POST /api/secure/interactions` lưu xuống cơ sở dữ liệu Backend.
  5. Khi thành công, khóa nút hẹn và hiển thị thông báo SnackBar xác nhận.

#### 1.4 Thực Hiện Cuộc Gọi Thực Tế Với `url_launcher`
- Nút **Gọi điện** trên thanh hành động và trong Popup liên hệ sẽ kích hoạt thư viện `url_launcher` với URL scheme `tel:<Phone>` để mở trình gọi điện thoại mặc định trên di động.
- Tự động lọc sạch khoảng trắng và ký tự đặc biệt khỏi số điện thoại.
- Bổ sung cấu hình Intent Queries trong `android/app/src/main/AndroidManifest.xml` hỗ trợ `android.intent.action.DIAL` giúp chạy tương thích chuẩn trên Android 11+.

#### 1.5 Nút Tròn Nổi Chat Trực Tiếp (Floating Action Button)
- Chuyển tính năng nhắn tin tư vấn trực tiếp với chủ BĐS thành nút tròn nổi màu cam nâu ở góc dưới bên phải màn hình (`bottom: 90, right: 16`).
- Bấm vào nút nổi sẽ mở khung chat Realtime Popup trò chuyện với chủ bài đăng.

---

### 2. Nâng Cấp DTO & Sửa Lỗi Authentication Profile

#### 2.1 Cập nhật `lib/dto/PropertyDTO.dart`
- Thêm 3 trường thông tin người đăng từ Backend: `userPhone`, `userFullname`, `userEmail`.
- Hiển thị Thẻ thông tin chủ bài đăng (`_buildSellerCard`) trên trang chi tiết BĐS.

#### 2.2 Sửa lỗi mất `id` người dùng trong `lib/dto/UserDTO.dart`
- Thêm thuộc tính `'id': id` vào hàm `toJson()` của `UserDTO.dart`.
- Giúp SharedPreferences lưu giữ đúng `senderId` khi đăng nhập, khắc phục triệt để lỗi không lấy được `senderId` khi gửi tương tác.
- Bổ sung cơ chế tự động gọi API `/api/secure/profile` để lấy `senderId` dự phòng nếu cache local bị thiếu.

---

### 3. Cải Tiến Bố Cục & Hiển Thị Danh Sách Bài Đăng (`Home.dart`, `PropertyList.dart`, `SaveNews.dart`)

- **Tối ưu thứ tự thông tin bài đăng**:
  - Tiêu đề bài đăng hiển thị nổi bật ở trên.
  - Số giá tiền hiển thị chữ to đậm màu cam nâu `#945331` (Cho bán) hoặc xanh lá `#2E7D32` (Cho thuê) bằng phông chữ Georgia.
  - Dòng vị trí kèm icon ghim.
  - Hàng thông số chi tiết: `2 PN` • `2 PT` • `1 Tầng` (icon `Icons.layers_outlined` ở chính giữa) • `85m²`.
- Định dạng hiển thị số tầng dạng số thuần (`1`, `2`) đồng bộ với số phòng ngủ và phòng tắm.

---

### 4. Giao Diện Đăng Tin Bất Động Sản (`lib/screens/seller/PostProperty.dart`)

- Tách ô lựa chọn **Hướng nhà** và **Giấy tờ pháp lý** thành 2 hàng riêng biệt full-width.
- Bổ sung `isExpanded: true` cho `DropdownButtonFormField` giúp nội dung tùy chọn hiển thị rộng rãi, không bị biểu tượng mũi tên hay container che khuất chữ.

---

### 5. Giao Diện Quản Lý Khách Hàng Chế Độ Chủ Đăng Tin (`lib/screens/seller/SellerCustomers.dart`)

- Tích hợp `url_launcher` vào nút **Gọi điện** giúp chủ nhà liên hệ lại khách hàng trực tiếp từ danh sách phản hồi.

---

### 6. Trạng Thái Kiểm Tra Mã Nguồn (Static Analysis)
- Đã chạy `flutter analyze` kiểm tra toàn bộ project: **0 Errors / 0 Warnings**.
