import 'package:flutter_test/flutter_test.dart';
import 'package:minha_cantina_app/main.dart';

void main() {
  testWidgets('MinhaCantinaApp inicializa com tabs de navegação', (WidgetTester tester) async {
    await tester.pumpWidget(const MinhaCantinaApp());
    await tester.pump();

    // Verifica tabs da barra de navegação
    expect(find.text('Cardápio'), findsOneWidget);
    expect(find.text('Pedido Ativo'), findsOneWidget);
    expect(find.text('Carteira'), findsOneWidget);
    expect(find.text('Atendedor'), findsOneWidget);
  });
}
