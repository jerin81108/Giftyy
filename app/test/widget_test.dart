import 'package:flutter_test/flutter_test.dart';
import 'package:dream_wishlist/main.dart';

void main() {
  testWidgets('Giftyy app launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const GiftyyApp());
    expect(find.text('GIFTYY'), findsOneWidget);
  });
}
