import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/screens/seller/PostProperty.dart';
import 'package:real_estate_frontend/screens/seller/SellerProperties.dart';

class ApiHarness with ApiPropertyMixin {
  ApiHarness(this.client);
  final http.Client client;
  @override
  http.Client get propertyClient => client;
}

http.Response jsonResponse(Object data, [int code = 200]) => http.Response(
  jsonEncode(data),
  code,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
const options = {
  'data': {
    'types': [
      {'id': 17, 'name': 'Bán'},
    ],
    'categories': [
      {'id': 35, 'name': 'Căn hộ'},
    ],
    'wards': [
      {'id': 91, 'name': 'Phường A', 'districtName': 'Quận B'},
    ],
  },
};
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_token': 'test-token'});
  });
  test(
    'parse ISO/epoch và reason/audit từ backend; owner fields không gửi metadata',
    () {
      final dto = PropertyDTO.fromJson({
        'id': 1,
        'status': 'Từ chối',
        'rejectionReason': 'Thiếu hồ sơ',
        'reviewedBy': 7,
        'reviewedAt': '2026-10-23T10:00:00Z',
        'createdDate': 0,
      });
      expect(dto.rejectionReason, 'Thiếu hồ sơ');
      expect(dto.reviewedBy, 7);
      expect(dto.reviewedAt!.year, 2026);
      expect(dto.createdDate!.millisecondsSinceEpoch, 0);
      expect(dto.toFields().containsKey('rejectionReason'), false);
      expect(dto.toFields().containsKey('reviewedAt'), false);
    },
  );
  test(
    'options JWT, multipart id/ward không ghi đè status/reason/audit, nhận DTO thật',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        if (request.method == 'GET') return jsonResponse(options);
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        expect(request.body, contains('name="id"'));
        expect(request.body, contains('name="wardId"'));
        expect(request.body, isNot(contains('rejectionReason')));
        return jsonResponse({
          'data': {
            'id': 19,
            'status': 'Từ chối',
            'rejectionReason': 'Lý do giữ nguyên',
          },
        });
      });
      final api = ApiHarness(client);
      expect((await api.fetchPropertyOptions())['types'][0]['id'], 17);
      final result = await api.saveProperty(
        PropertyDTO(id: 19, wardId: 91, title: 'Sửa nội dung'),
      );
      expect(result['success'], true);
      expect(result['data']['status'], 'Từ chối');
    },
  );
  test(
    '422 structured error và response thiếu xác nhận không báo success',
    () async {
      final invalid = ApiHarness(
        MockClient(
          (_) async => jsonResponse({
            'message': 'Validation',
            'data': {'wardId': 'Chọn phường hợp lệ'},
          }, 422),
        ),
      );
      expect(
        (await invalid.saveProperty(PropertyDTO(title: 'Tin')))['message'],
        contains('wardId: Chọn phường hợp lệ'),
      );
      final missing = ApiHarness(
        MockClient((_) async => jsonResponse({'data': {}})),
      );
      expect(
        (await missing.saveProperty(PropertyDTO(title: 'Tin')))['success'],
        false,
      );
    },
  );
  test('mine lỗi auth không biến thành danh sách rỗng', () async {
    final api = ApiHarness(
      MockClient((_) async => jsonResponse({'message': 'unauthorized'}, 401)),
    );
    await expectLater(api.fetchMyProperties(), throwsA(isA<Exception>()));
  });
  testWidgets('mine tách rejected/deleted, reason thật và tải lại sau lỗi', (
    tester,
  ) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      if (calls == 1) return jsonResponse({'message': 'unauthorized'}, 401);
      return jsonResponse({
        'data': [
          {
            'id': 1,
            'title': 'Tin bị từ chối',
            'status': 'Từ chối',
            'rejectionReason': 'Thiếu hồ sơ',
          },
          {'id': 2, 'title': 'Tin đã xóa', 'status': 'Đã xóa'},
        ],
      });
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SellerPropertiesScreen(client: client, onPostNewProperty: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tải lại'));
    await tester.pumpAndSettle();
    expect(find.text('Lý do từ chối: Thiếu hồ sơ'), findsOneWidget);
    await tester.tap(find.text('Bị từ chối').first);
    await tester.pumpAndSettle();
    expect(find.text('Tin bị từ chối'), findsOneWidget);
    expect(find.text('Tin đã xóa'), findsNothing);
    expect(calls, 2);
  });
  testWidgets(
    'mobile edit giữ draft khi network lỗi, không retry và chặn submit lặp',
    (tester) async {
      var saves = 0;
      final pending = Completer<http.Response>();
      final client = MockClient((request) async {
        if (request.method == 'GET') return jsonResponse(options);
        saves++;
        return pending.future;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: PostPropertyScreen(
            client: client,
            property: PropertyDTO(
              id: 2,
              typeId: 17,
              categoryId: 35,
              wardId: 91,
              title: 'Tin chỉnh sửa',
              price: 10,
              area: 20,
              address: 'Địa chỉ',
              legal: 'Sổ hồng riêng',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byType(ElevatedButton).last;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      expect(saves, 1);
      pending.completeError(http.ClientException('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Tin chỉnh sửa'), findsOneWidget);
      expect(saves, 1);
      expect(find.textContaining('Lỗi kết nối'), findsWidgets);
    },
  );
  testWidgets('options lỗi có retry, không dùng danh mục đoán', (tester) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      if (calls == 1) {
        return jsonResponse({'message': 'Không tải được danh mục'}, 403);
      }
      return jsonResponse(options);
    });
    await tester.pumpWidget(
      MaterialApp(home: PostPropertyScreen(client: client)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cho Bán'), findsNothing);
    await tester.tap(find.text('Tải lại danh mục'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Tải lại danh mục'), findsNothing);
  });
  testWidgets(
    'tạo mới chỉ báo tiếp nhận pending sau DTO và trả true để caller refetch',
    (tester) async {
      bool? result;
      final client = MockClient(
        (request) async => request.method == 'GET'
            ? jsonResponse(options)
            : jsonResponse({
                'data': {'id': 19, 'status': 'Chờ duyệt'},
              }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostPropertyScreen(
                        client: client,
                        property: PropertyDTO(
                          typeId: 17,
                          categoryId: 35,
                          wardId: 91,
                          title: 'Tin mới',
                          price: 10,
                          area: 20,
                          address: 'Địa chỉ',
                          legal: 'Sổ hồng riêng',
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Mở form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở form'));
      await tester.pumpAndSettle();
      final button = find.byType(ElevatedButton).last;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(result, true);
      expect(find.text(receivedPropertyMessage), findsOneWidget);
    },
  );
}
