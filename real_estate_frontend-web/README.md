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

## Các route chính

- `/`, `/properties`, `/properties/:id`: khám phá và xem bất động sản.
- `/login`, `/register`, `/forgot-password`: tài khoản.
- `/saved`, `/account`, `/messages`: khu vực người dùng.
- `/seller/overview`, `/seller/properties`, `/seller/post`, `/seller/customers`: khu vực người bán.
- `/faq`, `/terms`, `/privacy`: hỗ trợ và chính sách.

## Trạng thái tích hợp

- Chế độ trải nghiệm mặc định dùng 12 tin mock khi backend không phản hồi. Nhãn “Dữ liệu trải nghiệm” luôn hiển thị; đặt `VITE_USE_MOCKS=false` để kiểm thử lỗi API thật.
- Trong chế độ mock, có thể dùng bất kỳ tên đăng nhập và mật khẩu từ 6 ký tự để thử các route được bảo vệ.

- Danh sách, đăng nhập, đăng ký, hồ sơ, tin đã lưu và tin của người bán dùng hợp đồng API hiện có.
- Endpoint chi tiết hiện yêu cầu JWT nên giao diện dẫn khách đăng nhập và quay lại đúng tin.
- UI đăng tin đã có cấu trúc/validation cơ bản; danh mục động và gửi multipart cần hoàn thiện khi nguồn danh mục API được xác nhận.
- Chat WebSocket, khách hàng theo interaction, AI streaming và nội dung pháp lý chính thức đang hiển thị trạng thái trung thực thay vì dữ liệu giả.

Design direction và product truth nằm trong `DESIGN.md` và `PRODUCT.md`.
