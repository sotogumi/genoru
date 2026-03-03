import 'package:flutter_test/flutter_test.dart';
import 'package:genoru/main.dart';

void main() {
  testWidgets('GenoruApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GenoruApp());
    await tester.pumpAndSettle();

    // InputScreenが表示されることを確認
    expect(find.text('🧬 ゲノる'), findsOneWidget);
    expect(find.text('あなたの言葉をDNAに変換しよう'), findsOneWidget);
  });
}
