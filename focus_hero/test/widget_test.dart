import 'package:flutter_test/flutter_test.dart';
import 'package:focus_hero/main.dart';

void main() {
  testWidgets('Focus Hero smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FocusHeroApp());
    expect(find.text('专注'), findsWidgets);
  });
}
