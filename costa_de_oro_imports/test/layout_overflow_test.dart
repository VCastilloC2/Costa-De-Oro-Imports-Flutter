import 'package:costa_de_oro_imports/app/theme/app_theme.dart';
import 'package:costa_de_oro_imports/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:costa_de_oro_imports/features/auth/presentation/pages/login_page.dart';
import 'package:costa_de_oro_imports/features/auth/presentation/pages/register_page.dart';
import 'package:costa_de_oro_imports/features/auth/presentation/pages/reset_password_page.dart';
import 'package:costa_de_oro_imports/features/dashboard/domain/dashboard_models.dart';
import 'package:costa_de_oro_imports/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:costa_de_oro_imports/features/dashboard/presentation/widgets/income_chart_card.dart';
import 'package:costa_de_oro_imports/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:costa_de_oro_imports/features/dashboard/presentation/widgets/total_sales_card.dart';
import 'package:costa_de_oro_imports/features/dashboard/presentation/widgets/welcome_banner.dart';
import 'package:costa_de_oro_imports/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantallas de teléfono pequeño y texto grande: sin el antiguo escalado
/// manual, el layout tiene que adaptarse solo. Un desborde (RenderFlex
/// overflow) hace fallar la prueba.
void main() {
  setUpAll(() {
    // Sin red en las pruebas: se usa la fuente por defecto.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const screens = <String, Size>{
    'teléfono pequeño': Size(320, 640),
    'teléfono común': Size(375, 812),
  };

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required Size size,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child,
          ),
        ),
      ),
    );
    // Deja correr las animaciones de entrada.
    await tester.pump(const Duration(seconds: 3));
  }

  /// Ignora los errores de fuentes (no hay red) y deja pasar el resto.
  void ignoreFontErrors() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('GoogleFonts') ||
          details.exceptionAsString().contains('allowRuntimeFetching')) {
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  final pages = <String, Widget Function()>{
    'login': () => const LoginPage(),
    'registro': () => const RegisterPage(),
    'recuperar contraseña': () => const ForgotPasswordPage(),
    'restablecer contraseña': () => const ResetPasswordPage(),
  };

  for (final screen in screens.entries) {
    for (final page in pages.entries) {
      for (final textScale in [1.0, 1.3]) {
        testWidgets(
          '${page.key} sin desbordes en ${screen.key} (texto x$textScale)',
          (tester) async {
            ignoreFontErrors();
            await pump(
              tester,
              page.value(),
              size: screen.value,
              textScale: textScale,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    for (final textScale in [1.0, 1.3]) {
      testWidgets(
        'tarjetas del panel sin desbordes en ${screen.key} (texto x$textScale)',
        (tester) async {
          ignoreFontErrors();
          final data = DashboardData.skeleton;
          await pump(
            tester,
            Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DashboardHeader(
                    userName: data.profile.name,
                    pendingPurchases: 12,
                    onProfileTap: () {},
                  ),
                  WelcomeBanner(firstName: 'Alejandra', pendingPurchases: 12),
                  StatCard(
                    large: true,
                    title: 'Balance',
                    value: Formatters.money(1234567890),
                    detail: 'Ingresos \$5,9 M · Gastos \$2,1 M',
                    icon: Icons.account_balance_wallet_outlined,
                    iconBackground: Colors.pink,
                  ),
                  const IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Compras',
                            value: '142.339',
                            highlight: '35',
                            detail: ' pendientes',
                            icon: Icons.shopping_cart_outlined,
                            iconBackground: Colors.amber,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Clientes',
                            value: '39.354',
                            highlight: '120',
                            detail: ' productos',
                            icon: Icons.people_outline_rounded,
                            iconBackground: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IncomeChartCard(history: data.salesHistory, revealed: true),
                  TotalSalesCard(
                    totalSales: 98765432,
                    topProducts: data.topProducts,
                    revealed: true,
                  ),
                ],
              ),
            ),
            size: screen.value,
            textScale: textScale,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
