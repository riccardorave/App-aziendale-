import 'package:flutter_test/flutter_test.dart';
import 'package:booking_interno/main.dart';

void main() {
  testWidgets('BookSpace smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BookSpaceApp());
  });
}
