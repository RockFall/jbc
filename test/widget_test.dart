import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jbc/app.dart';
import 'package:jbc/core/bootstrap.dart';
import 'package:jbc/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mostra escolha de perfil quando não há perfil salvo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final bootstrap = await AppBootstrap.load(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWithValue(bootstrap),
        ],
        child: const JbcApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Quem é você'), findsOneWidget);
  });
}
