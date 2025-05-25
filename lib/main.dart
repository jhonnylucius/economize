import 'package:economize/features/financial_education/screens/goal_calculator_screen.dart';
import 'package:economize/features/financial_education/screens/tips_screen.dart';
import 'package:economize/model/budget/budget.dart';
import 'package:economize/screen/balance_screen.dart';
import 'package:economize/screen/budget/budget_compare_screen.dart';
import 'package:economize/screen/budget/budget_detail_screen.dart';
import 'package:economize/screen/budget/budget_list_screen.dart';
import 'package:economize/screen/costs_screen.dart';
import 'package:economize/screen/dashboard_screen.dart';
import 'package:economize/screen/goals_screen.dart';
import 'package:economize/screen/home_screen.dart';
import 'package:economize/screen/item_management_screen.dart';
import 'package:economize/screen/report_screen.dart';
import 'package:economize/screen/revenues_screen.dart';
import 'package:economize/screen/splash_screen.dart';
import 'package:economize/screen/trend_chart_screen.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o banco ANTES de qualquer coisa

  runApp(
    ChangeNotifierProvider(create: (_) => ThemeManager(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Economize',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: themeManager.currentTheme.colorScheme,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            cardTheme: CardTheme(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            scaffoldBackgroundColor:
                themeManager.currentTheme.scaffoldBackgroundColor,
            brightness: themeManager.currentTheme.brightness,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomeScreen(),
            '/dashboard': (context) => const DashBoardScreen(),
            '/costs': (context) => const CostsScreen(),
            '/revenues': (context) => const RevenuesScreen(),
            '/report': (context) => const ReportScreen(),
            '/budget/list': (context) => const BudgetListScreen(),
            '/items/manage': (context) => const ItemManagementScreen(),
            '/calculator': (context) => const GoalCalculatorScreen(),
            '/trend': (context) => const TrendChartScreen(),
            '/tips': (context) => const TipsScreen(),
            '/goals': (context) => const GoalsScreen(),
            '/balance': (context) => const BalanceScreen(),
            '/budget/detail': (context) {
              final budget =
                  ModalRoute.of(context)?.settings.arguments as Budget?;
              return BudgetDetailScreen(budget: budget!);
            },
            '/budget/compare': (context) {
              final budget =
                  ModalRoute.of(context)?.settings.arguments as Budget?;
              return BudgetCompareScreen(budget: budget!);
            },
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
        );
      },
    );
  }
}
