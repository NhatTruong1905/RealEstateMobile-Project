# Báo Cáo Thay Đổi Mã Nguồn (Flutter Frontend & Đồng bộ Backend)

## 📌 Tổng Quan
Cập nhật mã nguồn Flutter (`real_estate_frontend`) đồng bộ với những thay đổi mới nhất từ Backend (`APIPropertyController` & `PropertyRequestDTO`), bao gồm:
- Phân trang 1-indexed (hỗ trợ `currentPage`, `totalPages`, `totalItems`).
- Tìm kiếm & Lọc đa điều kiện (bổ sung đầy đủ các trường của `PropertyRequestDTO`).
- Quản lý danh sách bất động sản đã lưu (thả tim) độc lập, bảo toàn danh sách thả tim trên mọi danh mục và các trang khác nhau.

---

## 📁 Danh Sách Các File Đã Thay Đổi / Tạo Mới

### 1. `lib/dto/PropertyRequestDTO.dart` (Cập nhật DTO gửi request)
- **Thay đổi:**
  - Bổ sung và đồng bộ đầy đủ các thuộc tính với Backend DTO: `title`, `fromPrice`, `toPrice`, `area`, `address`, `districtId`, `wardId`, `floorCount`, `bedroomCount`, `bathroomCount`, `direction`, `legal`, `staffId`, `categoryId`, `typeId`, `statusProperty`.
  - Cập nhật các trường phân trang: `page` (bắt đầu từ 1) và `limit` (mặc định 6 items/trang).
  - Cập nhật hàm `toQueryParams()` để định dạng đúng các tham số Query Parameter gửi sang Backend (`fromPrice`, `toPrice`, `page`, `limit`, ...).

### 2. `lib/dto/PropertyPageResponseDTO.dart` (Tạo mới DTO nhận response phân trang)
- **Thay đổi:**
  - Tạo mới class `PropertyPageResponseDTO` hứng dữ liệu phân trang trả về từ Backend:
    - `content`: Danh sách `PropertyDTO`.
    - `currentPage`: Trang hiện tại (1-indexed).
    - `totalItems`: Tổng số bất động sản.
    - `totalPages`: Tổng số trang.

### 3. `lib/mixin/api/APIPropertyMixin.dart` (Cập nhật Service Gọi API)
- **Thay đổi:**
  - Bổ sung hàm `fetchPropertiesPage({PropertyRequestDTO? request})` để gọi GET `/api/properties` và trả về `PropertyPageResponseDTO`.
  - Thêm biến toàn cục `userFavoriteIds` (`Set<int>`) quản lý tất cả các ID bài viết mà tài khoản hiện tại đã lưu trên toàn hệ thống.
  - Cập nhật `fetchFavoriteProperties()` để lưu tất cả ID bài viết đã lưu vào `userFavoriteIds`.

### 4. `lib/screens/Home.dart` (Màn hình Trang chủ, Lọc & Phân trang)
- **Thay đổi:**
  - Cập nhật phân trang 1-indexed trong `_loadData()` và `_loadMoreData()` theo `currentPage` và `totalPages` nhận từ Backend API.
  - Nâng cấp BottomSheet bộ lọc đa điều kiện đầy đủ tiêu chí: Tên/Tiêu đề, Địa chỉ, Khoảng giá (`fromPrice` - `toPrice`), Diện tích (m²), Số tầng, Số phòng ngủ, Số phòng tắm, Hướng nhà, Pháp lý.
  - Cập nhật logic nút thả tim `_toggleSave`: Thêm/bớt ID vào `userFavoriteIds` và gửi toàn bộ `userFavoriteIds` lên Backend, giúp bảo toàn danh sách đã lưu khi người dùng chuyển danh mục hoặc phân trang.
  - Cập nhật hiển thị số liệu thực (`bedroomCount`, `bathroomCount`, `area`) cho các thẻ bất động sản.

### 5. `lib/screens/SaveNews.dart` (Màn hình Danh sách Đã lưu)
- **Thay đổi:**
  - Chuyển sang sử dụng danh sách `_savedProperties` độc lập, gọi trực tiếp API `/api/secure/favorite-properties` để lấy **tất cả** bất động sản đã lưu từ cơ sở dữ liệu (không bị phụ thuộc vào bài viết đang load ở Trang chủ).
  - Bổ sung tính năng vuốt xuống để làm mới (Pull-To-Refresh).
  - Cập nhật logic nút bỏ thả tim: loại bỏ ID khỏi `userFavoriteIds` và đồng bộ chính xác dữ liệu về Backend.
  - Hiển thị số liệu thực của bất động sản.

### 6. `lib/screens/MainScreen.dart` (Màn hình Điều hướng Tab chính)
- **Thay đổi:**
  - Cập nhật `ValueKey('saved_$_currentIndex')` cho `SavedNewsScreen` để tự động kích hoạt tải lại danh sách bài viết đã lưu từ Backend mỗi khi người dùng chuyển sang Tab "Đã lưu".
