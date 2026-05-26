import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:conexao_saude/data/models/lista_medicamento_model.dart';

class EstatisticasPage extends StatelessWidget {
  const EstatisticasPage({super.key});

  static const String _listaHomeKey = 'lista_home_inicial';

  // Lógica das frases motivacionais
  String _obterMensagemMotivacional(int dias) {
    if (dias == 0) return 'Tome a primeira dose para começar!';
    if (dias >= 1 && dias <= 5) return 'Um bom começo 🔥';
    if (dias >= 6 && dias <= 15) return 'Mandando muito bem 🚀';
    if (dias >= 16 && dias <= 30) return 'Meu deus você não esquece nunca 🤯';
    return 'Você é uma lenda 👑';
  }

  // Cor do fogo baseada na pontuação
  Color _obterCorOfensiva(int dias) {
    if (dias == 0) return Colors.grey;
    if (dias >= 1 && dias <= 5) return Colors.orange;
    if (dias >= 6 && dias <= 15) return Colors.deepOrange;
    if (dias >= 16 && dias <= 30) return Colors.redAccent;
    return Colors.purpleAccent; // Lenda
  }

  @override
  Widget build(BuildContext context) {
    // Escuta a mesma caixa do Hive que a Home Page
    final listasBox = Hive.box<ListaMedicamentoModel>('minhas_listas');

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Ofensivas e Recordes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          // Reatividade: atualiza a tela na mesma hora que o paciente toma o remédio na Home
          child: ValueListenableBuilder<Box<ListaMedicamentoModel>>(
            valueListenable: listasBox.listenable(),
            builder: (context, box, _) {
              final lista = box.get(_listaHomeKey);
              final medicamentos = lista == null 
                  ? <MedicamentoModel>[] 
                  : List<MedicamentoModel>.from(lista.medicamentos);

              if (medicamentos.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum medicamento registrado ainda.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: medicamentos.length,
                itemBuilder: (context, index) {
                  final med = medicamentos[index];
                  final corOfensiva = _obterCorOfensiva(med.ofensivaAtual);
                  final mensagem = _obterMensagemMotivacional(med.ofensivaAtual);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho: Nome e Recorde
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                med.nome,
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Recorde: ${med.maiorOfensiva}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // O Fogo do Duolingo e a Mensagem
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, color: corOfensiva, size: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${med.ofensivaAtual} Dias Seguidos',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: corOfensiva,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mensagem,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}