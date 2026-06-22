import 'package:conexao_saude/presentation/home/pages/main_page.dart';
import 'package:conexao_saude/data/models/lista_medicamento_model.dart';
import 'package:conexao_saude/core/theme/app_theme.dart';
import 'package:conexao_saude/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Garante que os plugins nativos sejam carregados antes do app iniciar
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebaseSafely();

  // Autentica o usuário anonimamente para acessar o Firestore
  await _autenticarAnonimamente();

  // Inicializa o hive pra armazenamento local de dados no Zorin OS
  await Hive.initFlutter();

  // 1. Registra o adaptador do Medicamento (o objeto interno)
  Hive.registerAdapter(MedicamentoModelAdapter());

  // 2. Registra o adaptador da Lista (o objeto principal)
  Hive.registerAdapter(ListaMedicamentoModelAdapter());

  // 3. Abre a caixa que vai guardar as listas (ex: "Remédios Pressão", "Suplementos")
  // Usamos ListaMedicamentoModel como o tipo da Box
  await Hive.openBox<ListaMedicamentoModel>('minhas_listas');

  // 4. Inicializa o serviço de notificações
  final notificationService = NotificationService();
  await notificationService.initialize();

  // 5. Reagenda notificações ao iniciar o app (caso tenham sido perdidas)
  await _reagendarNotificacoes();

  runApp(
    // Adicionado o ProviderScope para você já poder usar o Riverpod que conversamos
    const ProviderScope(child: ConexaoSaudeApp()),
  );
}

Future<void> _initializeFirebaseSafely() async {
  try {
    // Inicializa o firebase com as configs geradas do cli.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (error) {
    debugPrint('Firebase nao configurado para esta plataforma: $error');
  }
}

Future<void> _autenticarAnonimamente() async {
  try {
    final auth = FirebaseAuth.instance;
    
    // Verifica se já há um usuário autenticado
    if (auth.currentUser == null) {
      // Se não há, tenta fazer autenticação anônima (com retry)
      try {
        await auth.signInAnonymously();
        debugPrint('✓ Autenticação anônima realizada com sucesso');
      } on FirebaseAuthException catch (authError) {
        debugPrint('⚠️ Erro na autenticação anônima: ${authError.code} - ${authError.message}');
        // Em web, a auth pode estar desabilitada - isso é esperado
        if (authError.code == 'configuration-not-found') {
          debugPrint('ℹ️ Auth anônima não configurada para esta plataforma (pode ser web)');
        }
      }
    } else {
      debugPrint('✓ Usuário já autenticado: ${auth.currentUser?.uid}');
    }
  } catch (e) {
    debugPrint('❌ Erro ao autenticar anonimamente: $e');
  }
}

Future<void> _reagendarNotificacoes() async {
  try {
    final notificationService = NotificationService();
    final listasBox = Hive.box<ListaMedicamentoModel>('minhas_listas');
    
    // Pega todos os medicamentos salvos
    final lista = listasBox.get('lista_home_inicial');
    if (lista == null) return;

    // Reagenda notificações para cada medicamento ativo
    // Reagenda notificações para todos os medicamentos da lista
        for (int index = 0; index < lista.medicamentos.length; index++) {
          final medicamento = lista.medicamentos[index];
          
          // 1. Juntamos a data e a hora inicial para o alarme saber o ponto de partida
          final partesHora = medicamento.horario.split(':');
          final dataHoraExataInicio = DateTime(
            medicamento.dataInicio.year,
            medicamento.dataInicio.month,
            medicamento.dataInicio.day,
            int.parse(partesHora[0]),
            int.parse(partesHora[1]),
          );

          // 2. Chamamos a nova função que calcula os intervalos automaticamente
          await notificationService.agendarNotificacoesPorIntervalo(
            medicamentoId: index,
            medicamentoNome: medicamento.nome,
            dose: medicamento.dose,
            dataInicio: dataHoraExataInicio,
            intervaloHoras: medicamento.intervaloHoras,
            dataFim: medicamento.dataFim,
          );
        }
  } catch (e) {
    debugPrint('Erro ao reagendar notificações: $e');
  }
}

class ConexaoSaudeApp extends StatelessWidget {
  const ConexaoSaudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conexao Saude',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainPage(), // <--- MUDAMOS AQUI!
    );
  }
}
