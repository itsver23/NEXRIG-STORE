import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('shows setup message when Supabase is not configured', (tester) async {
    await tester.pumpWidget(const NexrigApp());
    expect(find.textContaining('Supabase is not configured'), findsOneWidget);
  });
}
