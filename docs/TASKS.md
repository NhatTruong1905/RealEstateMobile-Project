# Các công việc cần làm sau này

Bổ sung các task mới vào cuối file này.

## TASK-001 — Gửi email trạng thái bài đăng bằng Kafka

Trạng thái: TODO. Chưa triển khai Kafka.

Hiện tại dùng mail fake và tắt worker. Sự kiện thật vẫn lưu trong outbox hiện có.

### Các việc cần thực hiện

- [ ] Khảo sát lại outbox, scheduler, delivery và mailer; tái sử dụng luồng hiện có.
- [ ] Chốt schema/version sự kiện RECEIVED, APPROVED, REJECTED: event ID/key, property ID, người nhận từ DB, thời gian, nội dung và lý do từ chối.
- [ ] Thiết lập Kafka local/test và triển khai: broker, topic, consumer group, partition key, retention; credentials đặt trong secret.
- [ ] Xây dựng outbox publisher: chỉ publish sau commit nghiệp vụ, ghi nhận sau broker acknowledgement; retry khi lỗi.
- [ ] Xây dựng consumer gửi email; phân biệt trạng thái đã publish và đã gửi, không đánh dấu SENT chỉ vì publish thành công.
- [ ] Chống trùng theo event key; xử lý trường hợp SMTP gửi thành công nhưng consumer chưa ghi nhận/ack.
- [ ] Bổ sung retry/backoff, dead-letter topic, replay và giám sát lag/lỗi; hạn chế dữ liệu cá nhân trong log.
- [ ] Lập kế hoạch xử lý outbox PENDING cũ, thay scheduler bằng Kafka để tránh hai worker cùng gửi.
- [ ] Test với Kafka test environment và mail giả: ba loại email, rollback không phát sự kiện, duplicate/retry, broker lỗi, SMTP lỗi, replay.
- [ ] Cập nhật tài liệu chạy/deploy và rollback; chỉ bật gửi thật khi được cho phép.

### Tiêu chí hoàn thành

- Trạng thái và quyền xem bài do backend/DB quyết định, không chờ email.
- Email đúng chủ bài; từ chối có lý do thực tế đã lưu.
- Kafka/SMTP lỗi không làm mất sự kiện hoặc rollback bài đã lưu; có xử lý gửi trùng.
- Luồng OTP/quên mật khẩu giữ nguyên.

## Task tiếp theo

