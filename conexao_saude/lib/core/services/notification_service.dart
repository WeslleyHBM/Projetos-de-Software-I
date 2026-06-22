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

  Future<void> initialize() async {
    try {
      tzdata.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iOSSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // --- O CÓDIGO NOVO ENTRA AQUI ---
      // Pede permissão explícita para Alarmes Exatos no Android 12+
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.requestExactAlarmsPermission();
        await androidImplementation?.requestNotificationsPermission();
      }
      // --------------------------------

    } catch (e) {
      debugPrint('Erro ao inicializar notificações: $e');
    }
  }

  // ========================================================================
  // NOVO MOTOR DE AGENDAMENTO BLINDADO CONTRA CONGELAMENTOS
  // ========================================================================
  Future<void> agendarNotificacoesPorIntervalo({
    required int medicamentoId,
    required String medicamentoNome,
    required String dose,
    required DateTime dataInicio,
    required int intervaloHoras,
    required DateTime dataFim,
  }) async {
    try {
      // 1. Cancela alarmes antigos desse remédio
      await cancelarNotificacoesMedicamento(medicamentoId);

      if (Platform.isLinux) return;

      final locationTz = tz.local;
      final agora = DateTime.now();

      // 2. Descobre a próxima dose válida a partir de AGORA
      DateTime doseAtual = dataInicio;
      final int intervaloSeguro = intervaloHoras > 0 ? intervaloHoras : 8;

      if (doseAtual.isBefore(agora)) {
        final int diferencaHoras = agora.difference(doseAtual).inHours;
        final int numIntervalos = diferencaHoras ~/ intervaloSeguro;
        doseAtual = doseAtual.add(Duration(hours: numIntervalos * intervaloSeguro));

        while (doseAtual.isBefore(agora)) {
          doseAtual = doseAtual.add(Duration(hours: intervaloSeguro));
        }
      }

      // 3. Agenda as próximas 30 doses no sistema do telemóvel
      int dosesAgendadas = 0;

      while (doseAtual.isBefore(dataFim) && dosesAgendadas < 30) {
        final scheduledDate = tz.TZDateTime.from(doseAtual, locationTz);
        final idNotificacao = (medicamentoId * 100) + dosesAgendadas;

        // ESTE BLOCO TRY/CATCH IMPEDE A APLICAÇÃO DE CONGELAR!
        try {
          await _notificationsPlugin.zonedSchedule(
            idNotificacao,
            'Hora do Remédio! ⏰',
            'Está na hora de tomar: $medicamentoNome',
            scheduledDate,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'canal_medicamentos_urgente',
                'Lembretes de Medicamentos',
                channelDescription: 'Avisa a hora exata de tomar os remédios',
                importance: Importance.max, 
                priority: Priority.max,
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
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (erroAlarme) {
          debugPrint('Falha ao agendar alarme no sistema do telemóvel: $erroAlarme');
        }

        doseAtual = doseAtual.add(Duration(hours: intervaloSeguro));
        dosesAgendadas++;
      }
    } catch (erroGeral) {
      debugPrint('Erro crítico no serviço de notificações: $erroGeral');
    }
  }

  Future<void> cancelarNotificacoesMedicamento(int medicamentoId) async {
    for (int i = 0; i < 35; i++) {
      final idNotificacao = (medicamentoId * 100) + i;
      try {
        await _notificationsPlugin.cancel(idNotificacao);
      } catch (e) {
        // Ignora erros
      }
    }
  }

  Future<void> cancelarTodas() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Erro ao cancelar todas as notificações: $e');
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Paciente clicou na notificação!');
  }
}