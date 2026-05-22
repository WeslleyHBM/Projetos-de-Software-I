import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:conexao_saude/data/models/lista_medicamento_model.dart';
import 'package:conexao_saude/presentation/home/widgets/medicamento_item_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _listaHomeKey = 'lista_home_inicial';

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  Box<ListaMedicamentoModel> get _listasBox =>
      Hive.box<ListaMedicamentoModel>('minhas_listas');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Atualiza a variável de texto sempre que o paciente digita algo
  void _onSearchChanged(String value) {
    setState(() {
      _searchTerm = value.trim().toLowerCase();
    });
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
  }

  String _formatarData(DateTime date) {
    final dia = date.day.toString().padLeft(2, '0');
    final mes = date.month.toString().padLeft(2, '0');
    final ano = date.year.toString();
    return '$dia/$mes/$ano';
  }

  void _abrirDialogoTomarRemedio(MedicamentoModel item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final agora = DateTime.now();
            bool podeClicar = false;
            String mensagemStatus = '';
            Color corStatus = Colors.grey;

            if (item.ultimaDose == null) {
              final partesHora = item.horario.split(':');
              final horarioInicial = DateTime(
                item.dataInicio.year, item.dataInicio.month, item.dataInicio.day,
                int.parse(partesHora[0]), int.parse(partesHora[1])
              );
              
              final minutosParaInicio = horarioInicial.difference(agora).inMinutes;

              if (minutosParaInicio > 15) {
                podeClicar = false;
                mensagemStatus = 'Muito cedo! Faltam $minutosParaInicio minutos para a primeira dose.';
                corStatus = Colors.orange;
              } else {
                podeClicar = true;
                mensagemStatus = 'Pronto para tomar a primeira dose!';
                corStatus = Colors.green;
              }
            } else {
              final proximaDose = item.ultimaDose!.add(Duration(hours: item.intervaloHoras));
              final minutosParaProxima = proximaDose.difference(agora).inMinutes;

              if (minutosParaProxima > 15) {
                podeClicar = false;
                final horas = minutosParaProxima ~/ 60;
                final minutos = minutosParaProxima % 60;
                final tempoRestante = horas > 0 ? '${horas}h e ${minutos}min' : '${minutos}min';
                
                mensagemStatus = 'Aguarde o intervalo. Faltam $tempoRestante.';
                corStatus = Colors.orange;
              } else {
                podeClicar = true;
                mensagemStatus = 'Pronto para tomar!';
                corStatus = Colors.green;
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(item.nome, textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.medication, size: 80, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Dose: ${item.dose}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(mensagemStatus, textAlign: TextAlign.center, style: TextStyle(color: corStatus, fontWeight: FontWeight.bold)),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Tomar Remédio'),
                  onPressed: podeClicar ? () {
                    Navigator.of(dialogContext).pop();
                    
                    // Como estamos usando o ValueListenableBuilder, basta salvar no item
                    // que a tela toda vai se atualizar sozinha!
                    item.diasConsumidos += 1;
                    item.ultimaDose = DateTime.now();
                    item.save(); 
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dose de ${item.nome} registada com sucesso!'), backgroundColor: Colors.green),
                    );
                  } : null, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildWhiteBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Meus Medicamentos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _onSearch(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Pesquise na sua lista...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteBody() {
    final dataHoje = _formatarData(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          // --- A MÁGICA DE ESCUTAR O BANCO DE DADOS EM TEMPO REAL ---
          child: ValueListenableBuilder<Box<ListaMedicamentoModel>>(
            valueListenable: _listasBox.listenable(),
            builder: (context, box, _) {
              final lista = box.get(_listaHomeKey);
              final medicamentosSalvos = lista == null
                  ? <MedicamentoModel>[]
                  : List<MedicamentoModel>.from(lista.medicamentos);

              // Filtra os remédios do paciente baseado na barra de pesquisa
              final medicamentosFiltrados = medicamentosSalvos.where((item) {
                return item.nome.toLowerCase().contains(_searchTerm);
              }).toList();

              return ListView(
                children: [
                  const Text(
                    'Rotina Diária',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${medicamentosFiltrados.length} item(ns) encontrado(s)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  
                  if (medicamentosSalvos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
                      ),
                      child: const Text(
                        'Ainda não tem medicamentos registados. O seu médico irá adicioná-los no painel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else if (medicamentosFiltrados.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'Nenhum medicamento encontrado com esse nome na sua lista.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ...medicamentosFiltrados.map(
                      (item) {
                        // Calcula a duração em dias para exibir no card
                        final int duracaoDias = item.dataFim.difference(item.dataInicio).inDays;
                        
                        return MedicamentoItemCard(
                          nome: item.nome,
                          quantidade: item.dose,
                          hora: item.horario,
                          data: dataHoje,
                          diasConsumidos: item.diasConsumidos,
                          duracao: '$duracaoDias dias',
                          dataInicio: _formatarData(item.dataInicio),
                          dataFim: _formatarData(item.dataFim),
                          imageUrl: null,
                          onTap: () {
                            _abrirDialogoTomarRemedio(item);
                          }
                        );
                      }
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}