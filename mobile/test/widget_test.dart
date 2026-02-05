import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('shows bottom tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillSwapApp());

    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('İstekler'), findsOneWidget);
    expect(find.text('Mesajlar'), findsOneWidget);
    expect(find.text('Yetenekler'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
