import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  /// Agenda uma notificação para um horário específico
  Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String descricao,
    required DateTime dataHora,
    required String medicamentoNome,
  }) async {
    try {
      // Linux não suporta agendamento de notificações
      if (Platform.isLinux) {
        return;
      }

      // Converte para timezone local
      final locationTz = tz.local;
      final scheduledDate = tz.TZDateTime.from(dataHora, locationTz);

      // Não agenda se a data já passou
      if (scheduledDate.isBefore(tz.TZDateTime.now(locationTz))) {
        return;
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        titulo,
        descricao,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicamentos',
            'Alertas de Medicamentos',
            channelDescription: 'Notificações de horários de medicamentos',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Erro ao agendar notificação: $e');
    }
  }

  bool _isLinux() {
    try {
      // Se for Linux, zonedSchedule não está implementado
      return false; // Por enquanto assumir que não é Linux
    } catch (e) {
      return true;
    }
  }

  /// Agenda notificações recorrentes para um medicamento
  /// Cria notificações para todos os dias da semana no horário especificado
  Future<void> agendarNotificacoesRecorrentes({
    required int medicamentoId,
    required String medicamentoNome,
    required String dose,
    required String horario, // Formato: "HH:mm"
    required List<String> diasSemana, // ['Seg', 'Ter', ...]
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final mapa = {
      'Seg': DateTime.monday,
      'Ter': DateTime.tuesday,
      'Qua': DateTime.wednesday,
      'Qui': DateTime.thursday,
      'Sex': DateTime.friday,
      'Sab': DateTime.saturday,
      'Dom': DateTime.sunday,
    };

    final partes = horario.split(':');
    if (partes.length != 2) return;

    final hora = int.tryParse(partes[0]) ?? 0;
    final minuto = int.tryParse(partes[1]) ?? 0;

    // Agenda para cada dia da semana
    int idNotificacao = medicamentoId * 1000;

    for (final diaSemanaAbrev in diasSemana) {
      final diaSemanaNum = mapa[diaSemanaAbrev];
      if (diaSemanaNum == null) continue;

      // Encontra a próxima ocorrência desse dia
      var data = dataInicio;
      while (data.isBefore(dataFim)) {
        if (data.weekday == diaSemanaNum) {
          final dataHora =
              DateTime(data.year, data.month, data.day, hora, minuto);

          if (dataHora.isBefore(dataFim)) {
            await agendarNotificacao(
              id: idNotificacao,
              titulo: 'Hora do Remédio',
              descricao: '$medicamentoNome - Dose: $dose',
              dataHora: dataHora,
              medicamentoNome: medicamentoNome,
            );
            idNotificacao++;
          }
        }
        data = data.add(const Duration(days: 1));
      }
    }
  }

  /// Cancela todas as notificações de um medicamento
  Future<void> cancelarNotificacoesMedicamento(int medicamentoId) async {
    // Cancela um intervalo de IDs associados a este medicamento
    for (int i = 0; i < 1000; i++) {
      final idNotificacao = medicamentoId * 1000 + i;
      try {
        await _notificationsPlugin.cancel(idNotificacao);
      } catch (e) {
        // Ignora erros de notificações que não existem
      }
    }
  }

  /// Cancela uma notificação específica
  Future<void> cancelarNotificacao(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Erro ao cancelar notificação: $e');
    }
  }

  /// Cancela todas as notificações
  Future<void> cancelarTodas() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Erro ao cancelar todas as notificações: $e');
    }
  }

  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    // Aqui você pode tratar o clique na notificação
    debugPrint('Notificação clicada: ${notificationResponse.payload}');
  }
}
