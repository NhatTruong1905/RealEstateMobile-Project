import { MessageCircle, Sparkles } from "lucide-react";
import { Link } from "react-router-dom";
import { State } from "../../components/ui/State";

export function SimplePage({
  type,
}: {
  type: "forgot" | "messages" | "customers";
}) {
  const content = {
    forgot: [
      "Khôi phục tài khoản",
      "Luồng OTP sẽ kết nối với các endpoint khôi phục hiện có.",
    ],
    messages: [
      "Tin nhắn",
      "Kết nối chat thời gian thực đang chờ hoàn thiện hợp đồng WebSocket.",
    ],
    customers: [
      "Khách hàng quan tâm",
      "Danh sách được hiển thị khi dữ liệu interaction được kết nối.",
    ],
  }[type];
  return (
    <div className="page-shell">
      <div className="container narrow">
        <div className="page-intro compact-intro">
          <span className="eyebrow">Nhà Việt</span>
          <h1>{content[0]}</h1>
          <p>{content[1]}</p>
        </div>
        <State
          icon={type === "messages" ? <MessageCircle /> : <Sparkles />}
          title="Đang chuẩn bị nội dung"
          text="Khu vực này được giữ trung thực với trạng thái tích hợp hiện tại, không dùng dữ liệu minh họa thay cho dữ liệu thật."
          action={
            <Link className="button button-secondary" to="/">
              Về trang chủ
            </Link>
          }
        />
      </div>
    </div>
  );
}
export function NotFound() {
  return (
    <div className="not-found">
      <strong>404</strong>
      <span className="eyebrow">Đường dẫn không tồn tại</span>
      <h1>Có vẻ bạn đã rẽ nhầm.</h1>
      <p>Hãy quay về trang chủ hoặc tiếp tục khám phá kho bất động sản.</p>
      <div>
        <Link className="button button-primary" to="/">
          Về trang chủ
        </Link>
        <Link className="button button-secondary" to="/properties">
          Xem bất động sản
        </Link>
      </div>
    </div>
  );
}
