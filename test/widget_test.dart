import 'package:flutter_test/flutter_test.dart';
import 'package:book_shelf/main.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    await tester.pumpWidget(const BookShelfApp());
    expect(find.text('Книжная полка'), findsOneWidget);
  });
}
