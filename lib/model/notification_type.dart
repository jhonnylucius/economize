import 'package:flutter/material.dart';

enum NotificationType {
  info,
  success,
  warning,
  alert,
  reminder,
  tip,
  achievement,
  report
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.data = const {},
  });

  // Cria uma cópia com alterações
  NotificationItem copyWith({
    String? id,
    String? title,
    String? description,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  // Serialização para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  // Desserialização de JSON
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: NotificationType.values[json['type'] as int],
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
      data: json['data'] as Map<String, dynamic>,
    );
  }

  // Obter ícone baseado no tipo
  IconData get icon {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.alert:
        return Icons.error_outline;
      case NotificationType.reminder:
        return Icons.calendar_today;
      case NotificationType.tip:
        return Icons.lightbulb_outline;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.report:
        return Icons.summarize;
    }
  }

  // Obter cor baseada no tipo
  Color get color {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.reminder:
        return Colors.purple;
      case NotificationType.tip:
        return Colors.teal;
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.report:
        return Colors.indigo;
    }
  }

  // Obter tempo relativo
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return 'Há ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      return 'Há ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      return 'Há ${difference.inDays} ${difference.inDays == 1 ? 'dia' : 'dias'}';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    }
  }
}
