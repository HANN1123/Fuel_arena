import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_arena/app/fuel_arena_app.dart';

void main() {
  testWidgets('Fuel Arena app starts at splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FuelArenaApp()));

    expect(find.text('FUEL ARENA'), findsOneWidget);
    expect(find.text('연비로 증명해'), findsOneWidget);
  });
}
