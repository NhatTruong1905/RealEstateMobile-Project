# Nhà Việt — React frontend

Frontend web React + TypeScript cho hệ thống bất động sản Nhà Việt.

## Chạy local

```bash
npm install
copy .env.example .env
npm run dev
```

Backend chạy tại `http://localhost:8080/api`, được cấu hình trong `src/services/api/core/http.ts`.
Chatbot gọi FastAPI tại URL trong `VITE_AI_BASE_URL` (mặc định
`http://localhost:8000/api`). API key 9Router chỉ nằm trong `.env` của
`real-estate-ai`, tuyệt đối không đặt trong frontend.

Để kiểm tra chatbot, chạy AI service trước:

```powershell
cd ..\real-estate-ai
.\.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Sau đó chạy web trong terminal khác và mở nút chat ở góc phải dưới:

```powershell
cd ..\real_estate_frontend-web
npm run dev
```

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
├── services/api/      API tách theo auth, property, account, favorite và seller
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

- Frontend chỉ sử dụng dữ liệu từ backend; lỗi API được hiển thị để người dùng thử lại.

- Danh sách, đăng nhập, đăng ký, hồ sơ, tin đã lưu và tin của người bán dùng hợp đồng API hiện có.
- Khách có thể xem danh sách và chi tiết; lưu tin và đăng tin yêu cầu đăng nhập rồi quay lại đúng trang.
- UI đăng tin đã có cấu trúc/validation cơ bản; danh mục động và gửi multipart cần hoàn thiện khi nguồn danh mục API được xác nhận.
- AI chatbot đã gọi FastAPI qua streaming tại `/api/chat-rag/stream`.
- Chat WebSocket và khách hàng theo interaction đang chờ tích hợp backend tương ứng.

Design direction và product truth nằm trong `DESIGN.md` và `PRODUCT.md`.
