import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('giris ekrani gorunur', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillSwapApp());

    expect(find.text('İMECE'), findsOneWidget);
    expect(find.text('Giris Yap'), findsOneWidget);
    expect(find.text('Hesabin yok mu? Kayit ol'), findsOneWidget);
  });
}
