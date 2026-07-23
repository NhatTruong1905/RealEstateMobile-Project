import 'package:flutter/material.dart';

class FAQItem {
  final String category;
  final String question;
  final String answer;

  FAQItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String activeCategory = "Tất cả";
  int? expandedIndex;

  String searchQuery = "";

  final List<String> faqCategories = [
    "Tất cả",
    "Chung",
    "Tài khoản",
    "Giao dịch",
  ];

  final List<FAQItem> faqData = [
    FAQItem(
      category: "Chung",
      question: "Làm thế nào để tìm kiếm bất động sản?",
      answer:
          "Bạn có thể sử dụng thanh tìm kiếm ở trang chủ, nhập địa điểm, tên dự án hoặc sử dụng bộ lọc để tìm kiếm theo mức giá, diện tích và loại hình bất động sản.",
    ),
    FAQItem(
      category: "Chung",
      question: "Làm sao để lưu lại bất động sản tôi thích?",
      answer:
          "Chỉ cần nhấn vào biểu tượng trái tim (♡) ở góc trên bên phải của hình ảnh bất động sản. Mục đã lưu sẽ xuất hiện trong tab 'Đã lưu'.",
    ),
    FAQItem(
      category: "Tài khoản",
      question: "Làm thế nào để thay đổi mật khẩu?",
      answer:
          "Vào mục Hồ sơ > Cài đặt chung > Thông tin cá nhân > Đổi mật khẩu. Bạn sẽ cần nhập mật khẩu cũ trước khi đặt mật khẩu mới.",
    ),
    FAQItem(
      category: "Giao dịch",
      question: "Tôi có thể liên hệ trực tiếp với người bán không?",
      answer:
          "Có, trong trang chi tiết bất động sản, bạn sẽ thấy nút 'Liên hệ người bán' hoặc 'Gọi ngay' để trao đổi trực tiếp.",
    ),
    FAQItem(
      category: "Giao dịch",
      question: "Phí dịch vụ khi sử dụng ứng dụng là bao nhiêu?",
      answer:
          "Ứng dụng hoàn toàn miễn phí cho người đi tìm kiếm bất động sản. Các khoản phí chỉ áp dụng cho người đăng tin bán/cho thuê theo các gói dịch vụ.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = faqData.where((faq) {
      final matchesCategory =
          activeCategory == "Tất cả" || faq.category == activeCategory;
      final matchesSearch =
          faq.question.toLowerCase().contains(searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        expandedIndex = null;
                      });
                      Navigator.pop(context);
                    },
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
                    'Câu hỏi thường gặp',
                    style: TextStyle(
                      fontSize: 22,
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EEE6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF78736D), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            expandedIndex = null;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm câu hỏi...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Color(0xFF78736D),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: faqCategories.length,
                itemBuilder: (context, index) {
                  final cat = faqCategories[index];
                  final isSelected = activeCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => setState(() {
                        activeCategory = cat;
                        expandedIndex = null;
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A1918)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(color: const Color(0xFFE8E3DC)),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFFFCFBFA)
                                  : const Color(0xFF78736D),
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredFaqs.length,
                      itemBuilder: (context, index) {
                        final faq = filteredFaqs[index];
                        final isExpanded = expandedIndex == index;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.fastOutSlowIn,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8E3DC)),
                            boxShadow: isExpanded
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    expandedIndex = isExpanded ? null : index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          faq.question,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1918),
                                            fontFamily: 'Plus Jakarta Sans',
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isExpanded
                                              ? const Color(0xFF945331)
                                              : const Color(0xFFF4EEE6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0.0,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: isExpanded
                                                ? Colors.white
                                                : const Color(0xFF1A1918),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.fastOutSlowIn,
                                child: Container(
                                  height: isExpanded ? null : 0,
                                  width: double.infinity,
                                  clipBehavior: Clip.hardEdge,
                                  decoration: const BoxDecoration(),
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: Color(0xFFF4EEE6),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                          bottom: 16,
                                          top: 12,
                                        ),
                                        child: Text(
                                          faq.answer,
                                          style: const TextStyle(
                                            color: Color(0xFF78736D),
                                            fontSize: 14,
                                            height: 1.5,
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EEE6).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(
                              0xFF945331,
                            ).withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.help_outline,
                              color: Color(0xFF945331),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Vẫn cần hỗ trợ thêm?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1918),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Đội ngũ chăm sóc khách hàng của chúng tôi luôn sẵn sàng hỗ trợ bạn 24/7.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF78736D),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF945331),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Liên hệ ngay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

