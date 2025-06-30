import 'package:economize/accounts/screen/accounts_list_screen.dart';
import 'package:economize/features/financial_education/screens/goal_calculator_screen.dart';
import 'package:economize/features/financial_education/screens/tips_screen.dart';
import 'package:economize/model/budget/budget.dart';
import 'package:economize/scheduler/notification_scheduler.dart';
import 'package:economize/screen/balance_screen.dart';
import 'package:economize/screen/budget/budget_compare_screen.dart';
import 'package:economize/screen/budget/budget_detail_screen.dart';
import 'package:economize/screen/budget/budget_list_screen.dart';
import 'package:economize/screen/costs_screen.dart';
import 'package:economize/screen/dashboard_screen.dart';
import 'package:economize/screen/gamification/achievements_screen.dart';
import 'package:economize/screen/goals_screen.dart';
import 'package:economize/screen/home_screen.dart';
import 'package:economize/screen/item_management_screen.dart';
import 'package:economize/screen/report_screen.dart';
import 'package:economize/screen/revenues_screen.dart';
import 'package:economize/screen/splash_screen.dart';
import 'package:economize/screen/trend_chart_screen.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/gamification/achievement_service.dart';
import 'package:economize/service/notification_service.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AchievementService.initializeAchievements();
    Logger().i('✅ Sistema de conquistas inicializado!');
  } catch (e) {
    Logger().e('❌ Erro ao inicializar conquistas: $e');
  }

  final notificationService = NotificationService();
  await notificationService.initialize();

  final scheduler = NotificationScheduler();
  await scheduler.initialize();

  await _rescheduleAllNotifications();

  runApp(
    ChangeNotifierProvider(create: (_) => ThemeManager(), child: const MyApp()),
  );
}

Future<void> _rescheduleAllNotifications() async {
  try {
    final costsService = CostsService();
    final notificationService = NotificationService();

    final allCosts = await costsService.getAllCosts();
    final unpaidCosts = allCosts
        .where((cost) => !cost.pago && cost.data.isAfter(DateTime.now()))
        .toList();

    for (final cost in unpaidCosts) {
      await notificationService.schedulePaymentNotification(
        paymentId: cost.id,
        paymentName: cost.tipoDespesa,
        amount: cost.preco,
        dueDate: cost.data,
        isRecurrent: cost.recorrente,
      );
    }

    debugPrint('🔄 Reagendadas ${unpaidCosts.length} notificações');
  } catch (e) {
    debugPrint('❌ Erro ao reagendar notificações: $e');
  }
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
          theme: themeManager.currentTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomeScreen(),
            '/accounts': (context) =>
                const AccountsListScreen(), // <-- NOVA ROTA AQUI
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
            '/achievements': (context) => const AchievementsScreen(),
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
