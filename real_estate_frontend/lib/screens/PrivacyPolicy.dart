import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        'Chính sách bảo mật',
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
                      top: 24,
                      bottom: 80,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chính sách bảo mật thông tin',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1918),
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Áp dụng từ ngày 10/04/2026',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF78736D),
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildPolicySection(
                          '1. Giới thiệu về Chính sách bảo mật thông tin',
                          'CHÍNH SÁCH BẢO MẬT THÔNG TIN có hiệu lực từ ngày 10/04/2026. Công ty Cổ phần PropertySumDev Việt Nam và các đơn vị, chi nhánh, công ty liên quan đến Công ty Cổ phần PropertySumDev Việt Nam (sau đây gọi tắt là "Chúng tôi") điều hành website cam kết bảo vệ dữ liệu cá nhân của bạn một cách tối đa.',
                        ),
                        _buildPolicySection(
                          '2. Thu thập thông tin, dữ liệu cá nhân',
                          'Khi Bạn sử dụng Dịch vụ của Chúng tôi, Chúng tôi thu thập nhiều thông tin khác nhau từ Bạn và liên quan về Bạn, thiết bị và tương tác của Bạn với dịch vụ (gọi chung là "Thông tin"). Định nghĩa: Dữ liệu cá nhân là dữ liệu số hoặc thông tin định danh chính xác về thực thể cá nhân đó.',
                        ),
                        _buildPolicySection(
                          '3. Mục đích thu nhập, sử dụng và tiết lộ',
                          'Vì các mục đích mà chúng tôi có thể/sẽ thu thập, sử dụng, tiết lộ và/hoặc xử lý thông tin của Bạn tùy thuộc vào hoàn cảnh hiện tại, mục đích đó có thể không xuất hiện dưới đây. Tuy nhiên, Chúng tôi sẽ thông báo cho Bạn về mục đích khác tại thời điểm thu thập dữ liệu cụ thể.',
                        ),
                        _buildPolicySection(
                          '4. Độ chính xác và bảo mật',
                          'Bạn nên đảm bảo rằng tất cả thông tin của bạn được gửi cho chúng tôi là đầy đủ, chính xác, đúng sự thật và hợp lệ. Việc bạn không làm như vậy có thể dẫn đến việc chúng tôi không thể cung cấp cho bạn Dịch vụ mà Bạn đã yêu cầu.',
                        ),
                        _buildPolicySection(
                          '5. Rút lại sự đồng ý và yêu cầu truy cập, xóa, chỉnh sửa',
                          'Rút lại sự đồng ý: Bạn có thể rút lại sự đồng ý của bạn cho chúng tôi sử dụng thông tin của bạn, và bất kỳ sự đồng ý nào bạn đã cung cấp để nhận thông tin cập nhật tiếp thị trực tiếp từ hệ thống quảng cáo của bên thứ ba liên kết.',
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

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: Color(0xFF945331),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF945331),
                    fontFamily: 'Georgia',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              content,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color(0xFF1A1918),
                fontSize: 14.5,
                height: 1.6,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }
}


