// Testes de interface e navegação da Cantina de Mercearia
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_cantina_app/main.dart';

void main() {
  testWidgets('MinhaCantinaApp inicializa com tabs de navegação de mercearia/cantina', (WidgetTester tester) async {
    await tester.pumpWidget(const MinhaCantinaApp());
    await tester.pump();

    // Verifica tabs da barra de navegação adaptadas para cantina
    expect(find.text('Cantina'), findsOneWidget);
    expect(find.text('Reserva'), findsOneWidget);
    expect(find.text('Carteira'), findsOneWidget);
    expect(find.text('Balcão'), findsOneWidget);
  });
}
