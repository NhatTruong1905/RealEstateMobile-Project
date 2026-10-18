# Nhà Việt — React frontend

Frontend web React + TypeScript cho hệ thống bất động sản Nhà Việt.

## Chạy local

```bash
npm install
copy .env.example .env
npm run dev
```

Backend mặc định chạy tại `http://localhost:8080/api`. Điều chỉnh các biến `VITE_*` trong `.env` nếu dịch vụ dùng địa chỉ khác.

## Kiểm tra

```bash
npm run lint
npm run build
```

## Cấu trúc mã nguồn

```text
src/
├── components/        Thành phần dùng lại (brand, property, UI)
├── config/            Cấu hình tài nguyên
├── data/              Dữ liệu fallback phục vụ phát triển
├── hooks/             React hooks dùng chung
├── layouts/           Header, footer và bố cục trang
├── routes/            Route guard
├── screens/           Giao diện theo từng màn hình/nghiệp vụ
├── services/api/      API client và quản lý phiên
├── styles/            CSS tách theo khu vực giao diện
├── utils/             Hàm tiện ích
└── App.tsx            Khai báo route
```

## Các route chính

- `/`, `/properties`, `/properties/:id`: khám phá và xem bất động sản.
- `/login`, `/register`, `/forgot-password`: tài khoản.
- `/saved`, `/account`, `/messages`: khu vực người dùng.
- `/seller/overview`, `/seller/properties`, `/seller/post`, `/seller/customers`: khu vực người bán.
- `/faq`, `/terms`, `/privacy`: hỗ trợ và chính sách.

## Trạng thái tích hợp

- Chế độ phát triển dùng dữ liệu fallback khi backend không phản hồi; đặt `VITE_USE_MOCKS=false` để kiểm thử lỗi API thật.
- Trong chế độ mock, có thể dùng bất kỳ tên đăng nhập và mật khẩu từ 6 ký tự để thử các route được bảo vệ.

- Danh sách, đăng nhập, đăng ký, hồ sơ, tin đã lưu và tin của người bán dùng hợp đồng API hiện có.
- Khách có thể xem danh sách và chi tiết; lưu tin và đăng tin yêu cầu đăng nhập rồi quay lại đúng trang.
- UI đăng tin đã có cấu trúc/validation cơ bản; danh mục động và gửi multipart cần hoàn thiện khi nguồn danh mục API được xác nhận.
- Chat WebSocket, khách hàng theo interaction và AI streaming đang chờ tích hợp backend tương ứng.

Design direction và product truth nằm trong `DESIGN.md` và `PRODUCT.md`.
