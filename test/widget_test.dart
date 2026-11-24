import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/main.dart';

void main() {
  testWidgets('Muestra configuracion pendiente sin Supabase', (tester) async {
    await tester.pumpWidget(const InventarioApp());
    expect(find.text('Configura Supabase'), findsOneWidget);
  });
}
