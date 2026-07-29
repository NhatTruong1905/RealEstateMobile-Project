String formatPropertyPrice(double? price) {
  if (price == null || price <= 0) {
    return 'Thỏa thuận';
  }

  if (price >= 1000000000) {
    double ty = price / 1000000000;
    String tyStr = ty.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return '$tyStr Tỷ';
  } else if (price >= 1000000) {
    double trieu = price / 1000000;
    String trieuStr = trieu.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return '$trieuStr Triệu';
  } else {
    String priceStr = price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$priceStr VNĐ';
  }
}
