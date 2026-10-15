# UI/UX Pro Max và Impeccable trong phát triển frontend

## 1. Skill frontend là gì?

Trong các coding agent như Codex, skill là một tập hợp hướng dẫn, quy tắc và tài nguyên giúp agent thực hiện một quy trình lặp lại theo cách nhất quán. Skill không phải framework frontend, package Flutter hay thư viện component.

`UI/UX Pro Max` và `Impeccable` thường được nhắc đến như các skill cộng đồng hoặc bộ hướng dẫn dành cho thiết kế frontend. Tên, nội dung và khả năng cụ thể có thể khác nhau tùy repository hoặc nhà phát hành. Vì vậy cần kiểm tra `SKILL.md`, giấy phép và nguồn cài đặt trước khi sử dụng. Không nên mặc định chúng là skill chính thức của OpenAI.

Một skill frontend thường giúp agent:

- Phân tích đối tượng người dùng và mục tiêu của màn hình.
- Chọn visual direction, màu sắc và typography.
- Xây dựng component và design system nhất quán.
- Kiểm tra responsive, accessibility và trạng thái tương tác.
- Nhận diện giao diện chung chung hoặc thiếu phân cấp.
- Review và tinh chỉnh frontend sau khi chức năng đã hoạt động.

## 2. UI/UX Pro Max

### 2.1. Mục tiêu thường gặp

UI/UX Pro Max phù hợp với giai đoạn thiết kế hoặc tái cấu trúc toàn bộ trải nghiệm. Skill dạng này thường thiên về hệ thống và quy trình:

- Xác định persona và user journey.
- Xây dựng information architecture.
- Chọn palette, typography và spacing scale.
- Xây component library và design token.
- Định nghĩa layout responsive.
- Kiểm tra accessibility.
- Lựa chọn pattern theo loại sản phẩm.

### 2.2. Khi nào nên dùng?

- Bắt đầu một frontend mới.
- Thiết kế lại toàn bộ ứng dụng.
- Giao diện hiện thiếu tính nhất quán.
- Cần xây design system dùng chung.
- Cần rà soát luồng nghiệp vụ và khả năng sử dụng, không chỉ màu sắc.

### 2.3. Điểm mạnh

- Cho cái nhìn tổng thể từ UX đến UI.
- Thích hợp để chuẩn hóa nhiều màn hình.
- Giảm tình trạng mỗi màn hình sử dụng một style khác nhau.
- Hữu ích khi cần chuyển từ prototype sang sản phẩm có hệ thống.

### 2.4. Rủi ro

- Có thể đưa ra quá nhiều quy tắc hoặc lựa chọn cùng lúc.
- Dễ áp dụng một style chung mà chưa hiểu đúng người dùng bất động sản Việt Nam.
- Không thay thế nghiên cứu người dùng và usability test.
- Kết quả vẫn cần được kiểm tra trực tiếp trên thiết bị Flutter.

## 3. Impeccable

### 3.1. Mục tiêu thường gặp

Impeccable phù hợp với giai đoạn critique và polish. Trọng tâm thường là làm cho một giao diện đang hoạt động trở nên có chủ đích và chuyên nghiệp hơn:

- Cải thiện visual hierarchy.
- Căn chỉnh spacing và alignment.
- Giảm số lượng card, border, shadow hoặc decoration không cần thiết.
- Cải thiện typography và độ dễ đọc.
- Chỉnh trạng thái hover, pressed, loading và animation.
- Loại bỏ cảm giác “template” hoặc giao diện do AI tạo hàng loạt.
- Làm rõ primary action và luồng mắt của người dùng.

### 3.2. Khi nào nên dùng?

- Chức năng đã hoàn thành nhưng giao diện chưa tinh tế.
- Màn hình có quá nhiều thành phần tranh giành sự chú ý.
- Khoảng cách, màu sắc hoặc typography chưa đồng nhất.
- Cần một vòng review trước demo, nghiệm thu hoặc phát hành.
- Muốn cải thiện một màn hình cụ thể mà không thiết kế lại toàn bộ sản phẩm.

### 3.3. Điểm mạnh

- Tập trung vào chất lượng hoàn thiện.
- Phù hợp với quy trình review theo từng màn hình.
- Giúp phát hiện các chi tiết nhỏ ảnh hưởng mạnh đến cảm nhận sản phẩm.
- Có thể áp dụng sau khi đã có design system.

### 3.4. Rủi ro

- Một giao diện đẹp hơn chưa chắc dễ sử dụng hơn.
- Nếu user flow ban đầu chưa đúng, polish không giải quyết được vấn đề cốt lõi.
- Animation và hiệu ứng quá mức có thể làm giảm hiệu năng hoặc accessibility.
- Không nên thay đổi đồng thời quá nhiều chi tiết mà không có tiêu chí kiểm chứng.

## 4. So sánh nhanh

| Tiêu chí | UI/UX Pro Max | Impeccable |
|---|---|---|
| Trọng tâm | Hệ thống UI/UX tổng thể | Critique và hoàn thiện hình ảnh |
| Giai đoạn phù hợp | Khởi tạo hoặc redesign | Sau khi UI đã hoạt động |
| Phạm vi | Nhiều màn hình, user flow, design system | Một màn hình hoặc một luồng cụ thể |
| Kết quả mong đợi | Cấu trúc và ngôn ngữ thiết kế nhất quán | Giao diện tinh tế, rõ phân cấp hơn |
| Rủi ro chính | Quá nhiều quy tắc, thiếu dữ liệu người dùng | Đẹp nhưng không giải quyết sai UX |

Hai skill không loại trừ nhau. Quy trình phù hợp thường là:

```text
Phân tích người dùng và nghiệp vụ
  -> UI/UX Pro Max định hình UX và design system
  -> Triển khai Flutter
  -> Kiểm thử chức năng và usability
  -> Impeccable critique và polish
  -> Kiểm tra accessibility, responsive và hiệu năng
```

## 5. Áp dụng vào project bất động sản

### 5.1. Những vấn đề cần giải quyết trước khi polish

Frontend hiện có nhiều màn hình lớn, UI và logic được đặt chung, sử dụng nhiều `setState` và lưu khá nhiều trạng thái trong SharedPreferences. Vì vậy thứ tự hợp lý là:

1. Tách logic API và state khỏi widget.
2. Xây theme và design token.
3. Chuẩn hóa component dùng chung.
4. Kiểm tra lại user flow.
5. Sau đó mới polish từng màn hình.

Nếu bỏ qua bốn bước đầu, việc làm đẹp trực tiếp các file màn hình lớn sẽ khiến giao diện khó duy trì và dễ thiếu nhất quán.

### 5.2. Design direction đề xuất

Ứng dụng bất động sản nên tạo cảm giác đáng tin cậy, rõ ràng và tập trung vào nội dung, thay vì dùng quá nhiều gradient hoặc hiệu ứng.

- Hình ảnh bất động sản là visual anchor chính.
- Màu nền trung tính; dùng một màu thương hiệu và một màu nhấn.
- Giá, vị trí và trạng thái pháp lý phải có phân cấp rõ.
- Font hỗ trợ tiếng Việt tốt và có ít mức weight.
- Card không nên chứa quá nhiều icon hoặc badge.
- CTA chính như “Liên hệ”, “Đặt lịch xem” phải dễ nhận biết.
- Thông tin AI cần phân biệt rõ với dữ liệu xác thực từ backend.
- Animation ngắn và phục vụ phản hồi trạng thái, không dùng chỉ để trang trí.

### 5.3. Design token cơ bản

Nên định nghĩa tập trung trong Flutter theme:

- Màu thương hiệu, màu semantic và màu surface.
- Typography scale.
- Spacing scale, ví dụ 4, 8, 12, 16, 24 và 32.
- Border radius.
- Elevation/shadow.
- Duration và easing cho animation.
- Breakpoint cho phone, tablet và desktop/web nếu hỗ trợ.

Không hard-code màu, padding và text style riêng trong từng màn hình nếu chúng thuộc hệ thống chung.

## 6. Checklist dùng UI/UX Pro Max

### Product và UX

- Người dùng chính của màn hình là ai?
- Tác vụ quan trọng nhất là gì?
- Primary action có rõ ràng không?
- Luồng có bước nào thừa không?
- Empty state và error state đã có chưa?
- Thông tin nào cần xuất hiện trước khi người dùng ra quyết định?

### Design system

- Màu sắc có ý nghĩa semantic rõ ràng không?
- Typography có scale nhất quán không?
- Spacing có theo token không?
- Component giống nhau có cùng hành vi không?
- Có hỗ trợ dark mode nếu project yêu cầu không?

### Responsive và accessibility

- Có hoạt động khi tăng cỡ chữ không?
- Text có đủ tương phản không?
- Vùng chạm có đủ lớn không?
- Icon-only button có semantic label không?
- Form có label, validation và focus order hợp lý không?

## 7. Checklist dùng Impeccable

- Mỗi màn hình có một visual anchor chính không?
- Người dùng có biết cần nhìn và thao tác ở đâu đầu tiên không?
- Có quá nhiều card, border, shadow hoặc badge không?
- Khoảng trắng có giúp nhóm thông tin không?
- Heading và body text có phân cấp rõ không?
- CTA chính và CTA phụ có bị cạnh tranh không?
- Hình ảnh có đúng tỷ lệ và chất lượng không?
- Loading có gây layout shift không?
- Animation có truyền đạt trạng thái hay chỉ để trang trí?
- Giao diện có nhất quán với các màn hình còn lại không?
- Khi bỏ toàn bộ shadow trang trí, bố cục vẫn rõ ràng không?

## 8. Prompt mẫu

### 8.1. Prompt định hình UI/UX

```text
Hãy review luồng tìm kiếm bất động sản của ứng dụng Flutter này theo hướng UI/UX system-level.

Đối tượng chính: người mua nhà tại Việt Nam, phần lớn sử dụng điện thoại.
Tác vụ chính: nhập nhu cầu, lọc kết quả, xem chi tiết, lưu tin và liên hệ.

Yêu cầu:
- Phân tích information architecture và user journey.
- Đề xuất design direction, typography, màu sắc và spacing token.
- Xác định component dùng chung.
- Thiết kế đầy đủ loading, empty, error và disabled state.
- Đảm bảo accessibility và responsive.
- Giữ nguyên nghiệp vụ hiện tại nếu chưa chỉ ra lý do thay đổi.
- Trước khi sửa code, liệt kê vấn đề và mục tiêu đo lường được.
```

### 8.2. Prompt critique và polish

```text
Hãy critique và polish màn hình chi tiết bất động sản Flutter này.

Tập trung vào:
- Visual hierarchy.
- Typography và spacing.
- Chất lượng hiển thị hình ảnh.
- Sự nổi bật của giá, vị trí và CTA đặt lịch.
- Giảm card, border, shadow và icon không cần thiết.
- Loading/error state và accessibility.

Không thay đổi API hoặc nghiệp vụ. Mỗi thay đổi cần giải thích vấn đề UI/UX mà nó giải quyết. Sau khi sửa, chạy formatter, analyzer và test liên quan.
```

## 9. Cách đánh giá kết quả

Không nên kết luận giao diện tốt chỉ dựa trên cảm nhận. Có thể đo:

- Task completion rate.
- Thời gian tìm được một bất động sản phù hợp.
- Số bước hoặc số lần chạm để hoàn thành tác vụ.
- Tỷ lệ người dùng hiểu đúng bộ lọc AI.
- Tỷ lệ click vào bất động sản được đề xuất.
- SUS hoặc bảng hỏi Likert.
- Accessibility audit.
- Frame rendering time và jank trên thiết bị thật.

Nên so sánh phiên bản trước và sau thay đổi trên cùng một nhóm tác vụ.

## 10. Kết luận

UI/UX Pro Max phù hợp để định hình lại hệ thống trải nghiệm và design system. Impeccable phù hợp để critique và hoàn thiện giao diện sau khi cấu trúc và chức năng đã ổn định. Với project này, nên áp dụng theo thứ tự:

1. Refactor kiến trúc Flutter.
2. Xác định user flow và design system bằng cách tiếp cận UI/UX Pro Max.
3. Triển khai các component và màn hình.
4. Kiểm thử với người dùng.
5. Dùng cách tiếp cận Impeccable để polish trước khi demo hoặc phát hành.

Skill giúp agent làm việc nhất quán hơn nhưng không thay thế nghiên cứu người dùng, phản biện thiết kế, kiểm thử accessibility và kiểm tra trên thiết bị thực.
