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

  /// Solicita permissões necessárias
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ precisa de permissão explícita
      await Permission.notification.request();

      // Para notificações exatas (alarmes)
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
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

  /// Mostra uma notificação imediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    // CORRIGIDO: Removido NotificationPriority que não existe mais
    String? channelId,
    String? channelName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'economize_default',
      channelName ?? 'Economize Notificações',
      channelDescription: 'Notificações do app Economize',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6200EE), // Cor do seu app
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
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

  /// Agenda uma notificação para um momento específico
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
      channelName ?? 'Economize Pagamentos',
      channelDescription: 'Lembretes de pagamentos e vencimentos',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6200EE),
      enableVibration: true,
      playSound: true,
      // Configurações para aparecer na tela de bloqueio
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // CORRIGIDO: Removido parâmetro que não existe mais
    );

    debugPrint('⏰ Notificação agendada para: $scheduledDate - $title');
  }

  /// Agenda notificações recorrentes (ex: toda semana)
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

    // CORRIGIDO: Adicionado parâmetro obrigatório androidScheduleMode
    await _notifications.periodicallyShow(
      id,
      title,
      body,
      repeatInterval,
      details,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle, // ADICIONADO
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

  /// Verifica se as notificações estão habilitadas
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return true; // iOS geralmente permite durante a inicialização
  }

  /// Mostra configurações de notificação do sistema
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }
}
