import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // ADICIONADO: Criar canal de notificação para Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    // Configurações para Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações para iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configurações gerais
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializar o plugin
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permissões
    await _requestPermissions();

    _isInitialized = true;
    debugPrint('✅ Serviço de notificações push inicializado');
  }

  /// ADICIONADO: Criar canais de notificação para Android
  Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel(
        'economize_high_importance',
        'Lembretes Importantes',
        description: 'Notificações importantes do Economize',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'economize_payments',
        'Lembretes de Pagamento',
        description: 'Lembretes de vencimento de contas',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'economize_default',
        'Notificações Gerais',
        description: 'Notificações gerais do Economize',
        importance: Importance.defaultImportance,
        enableVibration: true,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// ATUALIZADO: Solicita permissões necessárias com configurações específicas para Android 12+
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ precisa de permissão explícita para notificações
      final notificationStatus = await Permission.notification.request();

      // Para notificações exatas (importante para lembretes)
      final exactAlarmStatus = await Permission.scheduleExactAlarm.request();

      // ADICIONADO: Para Android 12+ - ignorar otimizações de bateria
      if (Platform.isAndroid) {
        final ignoreBatteryOptimization =
            await Permission.ignoreBatteryOptimizations.request();
        debugPrint(
            'Permissão para ignorar otimização de bateria: $ignoreBatteryOptimization');
      }

      debugPrint('Permissão de notificação: $notificationStatus');
      debugPrint('Permissão de alarme exato: $exactAlarmStatus');
    }

    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Callback quando notificação é tocada
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificação tocada: ${response.payload}');
    // Aqui você pode navegar para uma tela específica baseada no payload
    // Exemplo: NavigationService.navigateTo(response.payload);
  }

  /// ATUALIZADO: Mostra uma notificação imediata com configurações otimizadas
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'economize_high_importance',
      channelName ?? 'Lembretes Importantes',
      channelDescription: 'Notificações importantes do app Economize',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6200EE),
      enableVibration: true,
      playSound: true,
      autoCancel: false,
      ongoing: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );

    debugPrint('📱 Notificação enviada: $title');
  }

  /// CORRIGIDO: Agenda uma notificação para um momento específico
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String? channelId,
    String? channelName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Converter para timezone local
    final tz.TZDateTime scheduledTZ =
        tz.TZDateTime.from(scheduledDate, tz.local);

    // Verificar se a data é no futuro
    if (scheduledTZ.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint(
          '⚠️ Tentativa de agendar notificação no passado: $scheduledDate');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'economize_payments',
      channelName ?? 'Lembretes de Pagamento',
      channelDescription: 'Lembretes de vencimentos e pagamentos',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6200EE),
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // CORRIGIDO: Removido parâmetro obsoleto
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    debugPrint('⏰ Notificação agendada para: $scheduledDate - $title');
  }

  /// CORRIGIDO: Agenda notificações recorrentes
  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'economize_recurring',
      'Economize Recorrentes',
      channelDescription: 'Lembretes recorrentes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // CORRIGIDO: Adicionado parâmetro androidScheduleMode obrigatório
    await _notifications.periodicallyShow(
      id,
      title,
      body,
      repeatInterval,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    debugPrint('🔄 Notificação recorrente agendada: $title');
  }

  /// Cancela uma notificação específica
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('❌ Notificação cancelada: $id');
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('❌ Todas as notificações canceladas');
  }

  /// Lista todas as notificações pendentes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// ATUALIZADO: Verifica se todas as permissões necessárias estão concedidas
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final notification = await Permission.notification.isGranted;
      final exactAlarm = await Permission.scheduleExactAlarm.isGranted;

      debugPrint('Notificação habilitada: $notification');
      debugPrint('Alarme exato habilitado: $exactAlarm');

      return notification && exactAlarm;
    }
    return true;
  }

  /// Mostra configurações de notificação do sistema
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  /// ADICIONADO: Método para testar notificação imediata
  Future<void> testNotification() async {
    await showNotification(
      id: 999,
      title: 'Teste de Notificação',
      body: 'Se você viu isso, as notificações estão funcionando!',
      payload: 'test',
    );
  }

  /// ADICIONADO: Método para agendar notificação de teste em 10 segundos
  Future<void> testScheduledNotification() async {
    final testDate = DateTime.now().add(const Duration(seconds: 10));

    await scheduleNotification(
      id: 998,
      title: 'Teste Agendamento',
      body: 'Esta notificação foi agendada para 10 segundos!',
      scheduledDate: testDate,
      payload: 'test_scheduled',
    );

    debugPrint('🧪 Notificação de teste agendada para: $testDate');
  }

  /// ADICIONADO: Método para debugar notificações pendentes
  Future<void> debugPendingNotifications() async {
    final pending = await getPendingNotifications();
    debugPrint('📋 Notificações pendentes: ${pending.length}');

    for (final notification in pending) {
      debugPrint('  - ID: ${notification.id}, Título: ${notification.title}');
    }
  }
}
