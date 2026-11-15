# Design system — Nhà Việt

## Direction

Một ấn phẩm địa ốc Việt Nam đương đại: bình tĩnh, có chất liệu, ưu tiên ảnh và thông tin ra quyết định. Hệ thống mượn kỷ luật của catalog kiến trúc — lề rộng, đường kẻ mảnh, số thứ tự lớn và typography giàu nhịp — nhưng mọi điều khiển vẫn là thành phần web quen thuộc.

## Mode

- Trang chủ: Persuade vừa đủ, dẫn thẳng vào tìm kiếm.
- Tìm kiếm, tài khoản và khu vực người bán: Operate, ưu tiên tốc độ và độ rõ.
- Trang chính sách và trợ giúp: Read.

## Tokens

- Nền: `#F5F1E8`; bề mặt: `#FFFCF6`; chữ: `#17251F`.
- Thương hiệu: `#174F43`; hover: `#103B33`; CTA: `#D9683A`.
- Viền: `#D8D1C4`; chữ phụ: `#65716B`; lỗi: `#B42318`.
- Display: Georgia/Cormorant-style serif hệ thống; UI/body: Inter/Aptos/system sans.
- Radius 6/12/20px; shadow chỉ dùng cho lớp nổi và card tương tác.
- Spacing 4/8/12/16/24/32/48/64/96px.

## Signature move

Số mục lớn và đường kẻ dọc màu cam tạo nhịp như mục lục catalog. Trên card bất động sản, ảnh chiếm ưu thế; giá, tiêu đề, vị trí và thông số đi theo đúng thứ tự ra quyết định.

## Interaction

- Focus ring 3px rõ; vùng chạm tối thiểu 44px.
- Hover 160–220ms; không thay đổi layout.
- Drawer mobile quản lý focus; reduced motion tắt chuyển động trang trí.
- Loading dùng skeleton có kích thước cố định; lỗi và empty state luôn có hành động tiếp theo.
- Điều hướng giữa các trang dùng View Transitions do React Router quản lý: nội dung cũ rời đi 180ms, nội dung mới vào 380ms; sidebar, header và chatbot giữ ổn định.
- Nền chọn menu người bán di chuyển giữa các mục trong 420ms; icon và nhãn luôn nằm trên nền chọn. Điều hướng liên tiếp thay thế chuyển động đang chạy và giữ đúng URL cuối cùng.
- Đăng nhập/đăng ký giữ hai panel trượt trực tiếp, không chồng thêm chuyển tiếp trang. Trình duyệt thiếu View Transitions dùng hiệu ứng vào trang nhẹ; reduced motion bỏ chuyển động không thiết yếu.

## Seller listing form

- `/seller/post` uses three steps: information, photos, review and submission.
- Keep fields mounted across steps so returning to edit preserves the current draft. No promise of persistence after reload.
- Group required information into transaction/price and location/legal sections; disclose optional property details on demand.
- Show the exact VND amount beside price entry. Preview selected photos, support adding/removing files, and validate the five-image JPG/PNG limit before submission.
- Review uses the user's current values and selected images. Clearly explain moderation; only confirm receipt after the API responds.
- Move focus to the step heading on navigation and the relevant input on validation failure. Keep the final request locked with a spinner until it settles.
- Desktop has a form with a narrow guidance column; mobile uses one column and a full-width primary action.

## Responsive layout

- Mobile: một cột, filter drawer, menu thu gọn.
- Tablet: hai cột, filter nằm trên kết quả.
- Desktop: max-width 1280px; danh sách có sidebar và grid 2–3 cột.

<!-- impeccable:direction-seed seed:90fd41718d87f02d -->
