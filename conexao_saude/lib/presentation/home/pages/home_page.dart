import 'package:flutter/cupertino.dart';
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

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Future<void> _abrirDialogoEditar(MedicamentoModel item, int indice) async {
    // Pede a senha do médico primeiro
    final senhaCorreta = await _pedirSenhaDoMedico();
    if (!senhaCorreta) return;

    final doseController = TextEditingController(text: item.dose);
    DateTime horarioSelecionado = _parseHorario(item.horario);
    DateTime dataInicio = item.dataInicio;
    DateTime dataFim = item.dataFim;
    int intervaloHoras = item.intervaloHoras;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar ${item.nome}'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: doseController,
                    decoration: const InputDecoration(
                      labelText: 'Dose',
                      hintText: 'Ex: 1 comprimido',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Horário',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext builder) {
                          return SizedBox(
                            height: 250,
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              use24hFormat: false,
                              initialDateTime: horarioSelecionado,
                              onDateTimeChanged: (DateTime novaHora) {
                                setDialogState(() {
                                  horarioSelecionado = novaHora;
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(horarioSelecionado.hour % 12 == 0 ? 12 : horarioSelecionado.hour % 12).toString().padLeft(2, '0')}:${horarioSelecionado.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            horarioSelecionado.hour < 12
                                ? Icons.wb_sunny
                                : Icons.nightlight_round,
                            color: horarioSelecionado.hour < 12
                                ? Colors.orange
                                : Colors.blueGrey,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Data de Início',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(_formatarData(dataInicio))),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () async {
                            final data = await showDatePicker(
                              context: context,
                              initialDate: dataInicio,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (data != null) {
                              setDialogState(() {
                                dataInicio = data;
                                if (dataFim.isBefore(dataInicio)) {
                                  dataFim = dataInicio.add(const Duration(days: 30));
                                }
                              });
                            }
                          },
                          child: const Text('Alterar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Data de Término',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(_formatarData(dataFim))),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () async {
                            final data = await showDatePicker(
                              context: context,
                              initialDate: dataFim,
                              firstDate: dataInicio,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (data != null) {
                              setDialogState(() {
                                dataFim = data;
                              });
                            }
                          },
                          child: const Text('Alterar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Intervalo entre doses (horas)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    value: intervaloHoras,
                    isExpanded: true,
                    items: [4, 6, 8, 12, 24]
                        .map((valor) => DropdownMenuItem(
                              value: valor,
                              child: Text('$valor horas'),
                            ))
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        intervaloHoras = valor ?? 8;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actionsOverflowAlignment: OverflowBarAlignment.start,
          actionsOverflowButtonSpacing: 8,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) return;

    final dose = doseController.text.trim();

    if (dose.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a dose para editar.')),
      );
      return;
    }

    // Obter a lista atual
    final listaAtual = _listasBox.get(_listaHomeKey);
    if (listaAtual == null) return;

    final medicamentos = List<MedicamentoModel>.from(listaAtual.medicamentos);
    
    // Encontrar o índice do medicamento
    final indiceMedicamento = medicamentos.indexWhere(
      (med) =>
          med.nome == item.nome &&
          med.dose == item.dose &&
          med.horario == item.horario,
    );

    if (indiceMedicamento == -1) return;

    // Criar um novo medicamento com os dados atualizados
    final novoMedicamento = MedicamentoModel(
      nome: item.nome,
      dose: dose,
      horario: '${horarioSelecionado.hour.toString().padLeft(2, '0')}:${horarioSelecionado.minute.toString().padLeft(2, '0')}',
      dataInicio: dataInicio,
      dataFim: dataFim,
      intervaloHoras: intervaloHoras,
      diasConsumidos: item.diasConsumidos,
      ultimaDose: item.ultimaDose,
    );

    // Remover o antigo e adicionar o novo
    medicamentos[indiceMedicamento] = novoMedicamento;

    // Salvar a lista atualizada
    await _listasBox.put(
      _listaHomeKey,
      ListaMedicamentoModel(
        titulo: 'Lista inicial',
        medicamentos: medicamentos,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicamento atualizado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  DateTime _parseHorario(String horario) {
    final partes = horario.split(':');
    final horas = int.parse(partes[0]);
    final minutos = int.parse(partes[1]);
    return DateTime(2026, 1, 1, horas, minutos);
  }

  Future<bool> _pedirSenhaDoMedico() async {
    final senhaController = TextEditingController();
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Acesso Restrito'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Para editar ou remover medicamentos, é necessário a senha do médico.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha do Médico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (senhaController.text == 'medico') {
                  Navigator.pop(dialogContext, true);
                } else {
                  Navigator.pop(dialogContext, false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Senha incorreta! Acesso negado.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Entrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  Future<void> _removerMedicamento(MedicamentoModel item) async {
    // Pede a senha do médico primeiro
    final senhaCorreta = await _pedirSenhaDoMedico();
    if (!senhaCorreta) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover Medicamento'),
        content: Text('Deseja remover "${item.nome}" da sua lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    // Obter a lista atual
    final listaAtual = _listasBox.get(_listaHomeKey);
    if (listaAtual == null) return;

    final medicamentos = List<MedicamentoModel>.from(listaAtual.medicamentos);
    
    // Encontrar e remover o medicamento
    medicamentos.removeWhere(
      (med) =>
          med.nome == item.nome &&
          med.dose == item.dose &&
          med.horario == item.horario,
    );

    // Salvar a lista atualizada
    await _listasBox.put(
      _listaHomeKey,
      ListaMedicamentoModel(
        titulo: 'Lista inicial',
        medicamentos: medicamentos,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.nome} foi removido da sua lista.'),
        backgroundColor: Colors.orange,
      ),
    );
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
                    ...medicamentosFiltrados.asMap().entries.map(
                      (entry) {
                        final item = entry.value;
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
                          },
                          onEdit: () {
                            _abrirDialogoEditar(item, entry.key);
                          },
                          onDelete: () {
                            _removerMedicamento(item);
                          },
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