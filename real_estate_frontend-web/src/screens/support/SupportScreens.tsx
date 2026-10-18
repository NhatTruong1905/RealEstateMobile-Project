import { useMemo, useState } from "react";
import {
  ChevronDown,
  FileText,
  Mail,
  Search,
  ShieldCheck,
} from "lucide-react";

type FaqItem = {
  category: "Chung" | "Tài khoản" | "Giao dịch";
  question: string;
  answer: string;
};

const faqItems: FaqItem[] = [
  {
    category: "Chung",
    question: "Làm thế nào để tìm kiếm bất động sản?",
    answer:
      "Bạn có thể sử dụng thanh tìm kiếm ở trang chủ hoặc bộ lọc trong trang Bất động sản. Hệ thống hỗ trợ tìm theo từ khóa, khu vực, nhu cầu mua bán hoặc cho thuê, mức giá và số phòng ngủ.",
  },
  {
    category: "Chung",
    question: "Làm sao để lưu lại bất động sản tôi thích?",
    answer:
      "Nhấn biểu tượng dấu trang trên thẻ bất động sản. Nếu chưa đăng nhập, bạn sẽ được yêu cầu đăng nhập và hệ thống sẽ tự lưu tin sau khi quay lại.",
  },
  {
    category: "Tài khoản",
    question: "Tôi có cần tài khoản để xem tin không?",
    answer:
      "Không. Bạn có thể xem danh sách và chi tiết bất động sản mà không cần đăng nhập. Tài khoản chỉ cần thiết khi lưu tin, nhắn tin, quản lý hồ sơ hoặc đăng tin mới.",
  },
  {
    category: "Tài khoản",
    question: "Tôi quên mật khẩu thì phải làm gì?",
    answer:
      "Chọn “Quên mật khẩu?” tại trang đăng nhập và làm theo hướng dẫn. Nếu vẫn không truy cập được tài khoản, hãy liên hệ qua email tn696199@gmail.com.",
  },
  {
    category: "Giao dịch",
    question: "Tôi có thể liên hệ trực tiếp với người đăng tin không?",
    answer:
      "Có. Trong trang chi tiết bất động sản, bạn có thể dùng số điện thoại được người đăng cung cấp hoặc mở phần tin nhắn để trao đổi.",
  },
  {
    category: "Giao dịch",
    question: "Nhà Việt có xác minh mọi thông tin đăng tải không?",
    answer:
      "Nhà Việt hỗ trợ trình bày và quản lý thông tin đăng, nhưng người dùng vẫn cần kiểm tra giấy tờ, hiện trạng, chủ thể giao dịch và các điều kiện liên quan trước khi đặt cọc hoặc thanh toán.",
  },
  {
    category: "Giao dịch",
    question: "Phí sử dụng nền tảng là bao nhiêu?",
    answer:
      "Việc tìm kiếm và xem bất động sản hiện được cung cấp miễn phí. Nếu có gói dịch vụ dành cho người đăng tin, mức phí và quyền lợi sẽ được hiển thị rõ trước khi người dùng xác nhận.",
  },
];

const categories = ["Tất cả", "Chung", "Tài khoản", "Giao dịch"] as const;

export function FAQPage() {
  const [category, setCategory] = useState<(typeof categories)[number]>("Tất cả");
  const [query, setQuery] = useState("");

  const filteredItems = useMemo(() => {
    const normalizedQuery = query.trim().toLocaleLowerCase("vi");
    return faqItems.filter(
      (item) =>
        (category === "Tất cả" || item.category === category) &&
        (!normalizedQuery ||
          item.question.toLocaleLowerCase("vi").includes(normalizedQuery) ||
          item.answer.toLocaleLowerCase("vi").includes(normalizedQuery)),
    );
  }, [category, query]);

  return (
    <div className="support-page">
      <section className="support-hero">
        <div className="container support-hero-inner">
          <span className="eyebrow">Trung tâm hỗ trợ</span>
          <h1>Câu hỏi thường gặp</h1>
          <p>Tìm câu trả lời nhanh về tài khoản, tìm kiếm và giao dịch bất động sản.</p>
          <label className="faq-search">
            <Search />
            <span className="sr-only">Tìm kiếm câu hỏi</span>
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Tìm kiếm câu hỏi..."
            />
          </label>
        </div>
      </section>
      <div className="container support-content">
        <div className="faq-categories" aria-label="Nhóm câu hỏi">
          {categories.map((item) => (
            <button
              className={category === item ? "active" : ""}
              type="button"
              onClick={() => setCategory(item)}
              key={item}
            >
              {item}
            </button>
          ))}
        </div>
        <div className="faq-list">
          {filteredItems.map((item) => (
            <details key={item.question}>
              <summary>
                <span>{item.question}</span>
                <ChevronDown />
              </summary>
              <p>{item.answer}</p>
            </details>
          ))}
          {!filteredItems.length && (
            <div className="faq-empty">Không tìm thấy câu hỏi phù hợp.</div>
          )}
        </div>
        <aside className="support-contact">
          <Mail />
          <div>
            <h2>Vẫn cần hỗ trợ thêm?</h2>
            <p>Gửi câu hỏi cho chúng tôi và mô tả rõ vấn đề bạn đang gặp.</p>
          </div>
          <a className="button button-primary" href="mailto:tn696199@gmail.com">
            Liên hệ qua email
          </a>
        </aside>
      </div>
    </div>
  );
}

type LegalSection = { title: string; paragraphs: string[] };

function LegalPage({
  eyebrow,
  title,
  introduction,
  icon,
  sections,
}: {
  eyebrow: string;
  title: string;
  introduction: string;
  icon: React.ReactNode;
  sections: LegalSection[];
}) {
  return (
    <div className="legal-page">
      <div className="container legal-layout">
        <aside className="legal-aside">
          <div className="legal-icon">{icon}</div>
          <span className="eyebrow">{eyebrow}</span>
          <h1>{title}</h1>
          <p>{introduction}</p>
          <small>Cập nhật lần cuối: 18/10/2026</small>
        </aside>
        <article className="legal-document">
          {sections.map((section, index) => (
            <section key={section.title} id={`section-${index + 1}`}>
              <span>{String(index + 1).padStart(2, "0")}</span>
              <div>
                <h2>{section.title}</h2>
                {section.paragraphs.map((paragraph) => (
                  <p key={paragraph}>{paragraph}</p>
                ))}
              </div>
            </section>
          ))}
          <div className="legal-contact">
            Nếu có câu hỏi về nội dung này, vui lòng liên hệ
            <a href="mailto:tn696199@gmail.com">tn696199@gmail.com</a>.
          </div>
        </article>
      </div>
    </div>
  );
}

export function TermsPage() {
  const sections: LegalSection[] = [
    {
      title: "Chấp nhận điều khoản",
      paragraphs: [
        "Khi truy cập hoặc sử dụng Nhà Việt, bạn xác nhận đã đọc, hiểu và đồng ý tuân thủ các điều khoản này. Nếu không đồng ý, bạn nên ngừng sử dụng nền tảng.",
        "Người dùng có trách nhiệm cung cấp thông tin chính xác, bảo vệ thông tin đăng nhập và chịu trách nhiệm đối với hoạt động phát sinh từ tài khoản của mình.",
      ],
    },
    {
      title: "Nội dung và quyền sở hữu trí tuệ",
      paragraphs: [
        "Bạn chỉ được đăng hình ảnh, mô tả và tài liệu mà bạn có quyền sử dụng. Khi đăng nội dung, bạn cho phép Nhà Việt lưu trữ, hiển thị, định dạng và phân phối nội dung đó trong phạm vi cần thiết để vận hành dịch vụ.",
        "Bạn vẫn giữ quyền sở hữu đối với nội dung hợp pháp của mình. Bạn có trách nhiệm bảo đảm nội dung không xâm phạm quyền tác giả, nhãn hiệu, quyền riêng tư hoặc quyền hợp pháp của bên thứ ba.",
      ],
    },
    {
      title: "Tin đăng và khu vực tương tác",
      paragraphs: [
        "Nhà Việt có thể cung cấp khu vực đăng tin, lưu tin, nhắn tin và các tính năng tương tác khác. Người dùng không được đăng thông tin sai lệch, nội dung lừa đảo, xúc phạm, trái pháp luật hoặc gây ảnh hưởng đến an toàn của người khác.",
        "Nền tảng có quyền ẩn hoặc gỡ nội dung vi phạm, giới hạn tính năng hoặc khóa tài khoản khi cần bảo vệ cộng đồng và hệ thống.",
      ],
    },
    {
      title: "Giao dịch bất động sản",
      paragraphs: [
        "Nhà Việt là nền tảng hỗ trợ kết nối và cung cấp thông tin. Người mua, người thuê và người đăng tin tự chịu trách nhiệm xác minh danh tính, quyền sở hữu, giấy tờ pháp lý, hiện trạng và điều kiện giao dịch.",
        "Không chuyển tiền hoặc đặt cọc khi chưa kiểm tra đầy đủ. Mọi thỏa thuận và thanh toán giữa các bên được thực hiện trên cơ sở tự nguyện và theo quy định pháp luật.",
      ],
    },
    {
      title: "Thay đổi và chấm dứt dịch vụ",
      paragraphs: [
        "Nhà Việt có thể cập nhật tính năng hoặc điều khoản để phù hợp với hoạt động thực tế. Thay đổi quan trọng sẽ được thông báo trên nền tảng khi cần thiết.",
      ],
    },
  ];

  return (
    <LegalPage
      eyebrow="Quy định và chính sách"
      title="Điều khoản sử dụng"
      introduction="Các nguyên tắc áp dụng khi bạn truy cập, đăng tin và tương tác trên Nhà Việt."
      icon={<ShieldCheck />}
      sections={sections}
    />
  );
}

export function PrivacyPage() {
  const sections: LegalSection[] = [
    {
      title: "Phạm vi áp dụng",
      paragraphs: [
        "Chính sách này mô tả cách Nhà Việt thu thập, sử dụng, lưu trữ và bảo vệ dữ liệu khi bạn truy cập website, tạo tài khoản hoặc sử dụng các tính năng của nền tảng.",
      ],
    },
    {
      title: "Thông tin được thu thập",
      paragraphs: [
        "Tùy cách sử dụng dịch vụ, dữ liệu có thể gồm họ tên, tên đăng nhập, email, số điện thoại, thông tin hồ sơ, tin đăng, nội dung trao đổi và các lựa chọn đã lưu.",
        "Hệ thống cũng có thể ghi nhận thông tin kỹ thuật cần thiết như loại thiết bị, trình duyệt, thời điểm truy cập và nhật ký lỗi nhằm duy trì an toàn và cải thiện trải nghiệm.",
      ],
    },
    {
      title: "Mục đích sử dụng dữ liệu",
      paragraphs: [
        "Dữ liệu được sử dụng để cung cấp tài khoản, hiển thị và quản lý tin đăng, lưu bất động sản, hỗ trợ liên hệ, xử lý yêu cầu hỗ trợ và bảo vệ nền tảng khỏi hành vi lạm dụng.",
        "Nhà Việt không bán dữ liệu cá nhân. Thông tin chỉ được chia sẻ khi cần cung cấp dịch vụ, tuân thủ nghĩa vụ pháp lý hoặc khi có sự đồng ý phù hợp của bạn.",
      ],
    },
    {
      title: "Độ chính xác, lưu trữ và bảo mật",
      paragraphs: [
        "Bạn nên bảo đảm thông tin cung cấp là đầy đủ và chính xác. Dữ liệu được lưu trong thời gian cần thiết cho mục đích vận hành, giải quyết tranh chấp và thực hiện nghĩa vụ liên quan.",
        "Nhà Việt áp dụng các biện pháp kỹ thuật và tổ chức hợp lý để hạn chế truy cập, thay đổi, tiết lộ hoặc mất dữ liệu trái phép.",
      ],
    },
    {
      title: "Quyền của bạn",
      paragraphs: [
        "Bạn có thể yêu cầu xem, chỉnh sửa hoặc xóa dữ liệu cá nhân; rút lại sự đồng ý; hoặc đề nghị ngừng nhận thông tin tiếp thị. Một số dữ liệu có thể cần được giữ lại nếu pháp luật hoặc nghĩa vụ giải quyết giao dịch yêu cầu.",
      ],
    },
  ];

  return (
    <LegalPage
      eyebrow="Bảo vệ thông tin"
      title="Chính sách quyền riêng tư"
      introduction="Cách Nhà Việt xử lý dữ liệu cá nhân và các quyền bạn có đối với thông tin của mình."
      icon={<FileText />}
      sections={sections}
    />
  );
}
