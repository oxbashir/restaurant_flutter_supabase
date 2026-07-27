import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/app.dart';

void main() {
  testWidgets('Sabor app boots to splash brand', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SaborApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Sabor'), findsOneWidget);

    // Flush splash navigation timer.
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
