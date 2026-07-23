import 'package:flutter/material.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300) {
        if (!_showBackToTop) {
          setState(() => _showBackToTop = true);
        }
      } else {
        if (_showBackToTop) {
          setState(() => _showBackToTop = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE8E3DC)),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFF1A1918),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Điều khoản thỏa thuận',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1918),
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFE8E3DC).withValues(alpha: 0.5),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 32,
                      bottom: 80,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF945331).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.gpp_good_outlined,
                            color: Color(0xFF945331),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Quy định & Chính sách',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1918),
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Quyền sở hữu trí tuệ đối với nội dung'),
                        _buildParagraph(
                          'Với việc đưa nội dung lên vùng tương tác bất kỳ, bạn tự động chấp nhận và/hoặc cam đoan rằng, chủ sở hữu của nội dung đó, hoặc là bạn, hoặc là nhóm thứ ba, đã cho website realestate.com.vn quyền và giấy phép không phải trả tiền bản quyền, lâu dài, không thay đổi, không loại trừ, không hạn chế để sử dụng, mô phỏng, thay đổi, sửa lại, công bố, dịch thuật, tạo các sản phẩm phái sinh, cấp phép con, phân phối, thực hiện và hiển thị nội dung đó, toàn phần hay từng phần, khắp thế giới và/hoặc kết hợp nó với các công việc khác ở dạng bất kỳ, qua các phương tiện truyền thông hoặc công nghệ hiện tại hay sẽ phát triển sau này theo điều khoản đầy đủ của Quyền Sở hữu Trí tuệ bất kỳ trong nội dung đó.',
                        ),
                        _buildParagraph(
                          'Bạn cũng cho phép website realestate.com.vn cấp giấy phép con cho bên thứ ba quyền không hạn chế để thực hiện bất kỳ quyền nào ở trên với nội dung đó. Bạn cũng cho phép người dùng truy cập, xem, lưu và mô phỏng lại nội dung để sử dụng riêng. Bạn cũng cho phép website realestate.com.vn dùng tên và logo công ty/cá nhân vì các mục đích tiếp thị.',
                        ),

                        const SizedBox(height: 16),

                        _buildSectionTitle('3. Các vùng tương tác'),
                        _buildParagraph(
                          'Bạn thừa nhận, website realestate.com.vn có thể chứa các vùng tương tác khác nhau. Những vùng tương tác này cho phép phản hồi tới website realestate.com.vn và tương tác thời gian thực giữa những người sử dụng. Bạn cũng hiểu rằng, website realestate.com.vn không kiểm soát các thông báo, thông tin hoặc các tập tin được phân phối tới các vùng tương tác như vậy và rằng, website realestate.com.vn có thể cho bạn và những người sử dụng khác khả năng tạo và quản lý một vùng tương tác.',
                        ),
                        _buildParagraph(
                          'Tuy nhiên, website realestate.com.vn, công ty mẹ, hoặc các chi nhánh, cũng như các giám đốc, nhân viên, những người làm thuê và các đại lý tương ứng không chịu trách nhiệm về nội dung trong vùng tương tác bất kỳ. Việc sử dụng và quản lý một vùng tương tác của bạn sẽ bị chi phối bởi Điều khoản Thoả thuận này và các quy tắc bổ sung bất kỳ, hoặc bởi các thủ tục hoạt động của vùng tương tác bất kỳ do bạn hay người sử dụng khác thiết lập. Bạn công nhận rằng, website realestate.com.vn không thể và không có ý định sàng lọc các thông tin trước. Ngoài ra, vì website realestate.com.vn khuyến khích liên lạc mở và không thiên vị trong các vùng tương tác, nền tảng không đảm bảo tính chính xác, tính toàn vẹn hoặc chất lượng của bất kỳ nội dung nào được truyền tải.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              right: 20,
              bottom: _showBackToTop ? 24 : -60,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showBackToTop ? 0.7 : 0.0,
                child: FloatingActionButton(
                  onPressed: _scrollToTop,
                  mini: true,
                  backgroundColor: const Color(0xFF78736D),
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1918),
          fontFamily: 'Georgia',
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: const TextStyle(
          color: Color(0xFF78736D),
          fontSize: 15,
          height: 1.6,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }
}

