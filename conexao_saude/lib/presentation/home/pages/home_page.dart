import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:conexao_saude/data/models/lista_medicamento_model.dart';
import 'package:conexao_saude/presentation/home/widgets/medicamento_item_card.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _listaHomeKey = 'lista_home_inicial';
  static const List<String> _diasSemanaPadrao = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sab',
    'Dom',
  ];

  static const List<_MedicamentoCatalogo> _catalogoFake = [
    _MedicamentoCatalogo(
      nome: 'Dipirona',
      dosePadrao: '1 comprimido',
      horarioPadrao: '08:00',
    ),
    _MedicamentoCatalogo(
      nome: 'Vitamina D',
      dosePadrao: '2 gotas',
      horarioPadrao: '12:30',
    ),
    _MedicamentoCatalogo(
      nome: 'Losartana',
      dosePadrao: '1 comprimido',
      horarioPadrao: '20:00',
    ),
    _MedicamentoCatalogo(
      nome: 'Paracetamol',
      dosePadrao: '1 comprimido',
      horarioPadrao: '14:00',
    ),
    _MedicamentoCatalogo(
      nome: 'Omeprazol',
      dosePadrao: '1 capsula',
      horarioPadrao: '07:00',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  List<MedicamentoModel> _medicamentosSalvos = [];
  bool _isLoading = true;

  Box<ListaMedicamentoModel> get _listasBox =>
      Hive.box<ListaMedicamentoModel>('minhas_listas');

  @override
  void initState() {
    super.initState();
    _carregarMedicamentosSalvos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarMedicamentosSalvos() async {
    final lista = _listasBox.get(_listaHomeKey);

    if (lista == null) {
      await _listasBox.put(
        _listaHomeKey,
        ListaMedicamentoModel(titulo: 'Lista inicial', medicamentos: const []),
      );
      if (!mounted) return;
      setState(() {
        _medicamentosSalvos = [];
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _medicamentosSalvos = List<MedicamentoModel>.from(lista.medicamentos);
      _isLoading = false;
    });
  }

  Future<void> _adicionarMedicamentoNoHive({
    required String nome,
    required String dose,
    required String horario,
    required List<String> diasSemana,
  }) async {
    final listaAtual = _listasBox.get(_listaHomeKey);
    final medicamentos = listaAtual == null
        ? <MedicamentoModel>[]
        : List<MedicamentoModel>.from(listaAtual.medicamentos);

    final jaExiste = medicamentos.any(
      (item) =>
          item.nome.toLowerCase() == nome.toLowerCase() &&
          item.dose.toLowerCase() == dose.toLowerCase() &&
          item.horario == horario &&
          _chavesDiasSemana(item.diasSemana) == _chavesDiasSemana(diasSemana),
    );

    if (jaExiste) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esse remedio ja foi adicionado.')),
      );
      return;
    }

    medicamentos.add(
      MedicamentoModel(
        nome: nome,
        dose: dose,
        horario: horario,
        diasSemana: diasSemana,
      ),
    );

    await _listasBox.put(
      _listaHomeKey,
      ListaMedicamentoModel(
        titulo: 'Lista inicial',
        medicamentos: medicamentos,
      ),
    );

    if (!mounted) return;
    setState(() {
      _medicamentosSalvos = medicamentos;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nome adicionado na sua lista inicial.')),
    );
  }

  Future<void> _abrirDialogoAdicionar(_MedicamentoCatalogo item) async {
    final doseController = TextEditingController(text: item.dosePadrao);
    final horarioController = TextEditingController(text: item.horarioPadrao);
    final diasSelecionados = <String>[];

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adicionar ${item.nome}'),
          content: SingleChildScrollView(
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
                const SizedBox(height: 12),
                TextField(
                  controller: horarioController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Horario',
                    hintText: 'Ex: 08:00',
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Dias da semana',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _diasSemanaPadrao.map((dia) {
                    final selecionado = diasSelecionados.contains(dia);
                    return FilterChip(
                      label: Text(dia),
                      selected: selecionado,
                      onSelected: (value) {
                        setDialogState(() {
                          if (value) {
                            diasSelecionados.add(dia);
                          } else {
                            diasSelecionados.remove(dia);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
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
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) {
      doseController.dispose();
      horarioController.dispose();
      return;
    }

    final dose = doseController.text.trim();
    final horario = horarioController.text.trim();

    doseController.dispose();
    horarioController.dispose();

    if (dose.isEmpty || horario.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha dose e horario para adicionar.'),
        ),
      );
      return;
    }

    if (diasSelecionados.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um dia da semana.')),
      );
      return;
    }

    await _adicionarMedicamentoNoHive(
      nome: item.nome,
      dose: dose,
      horario: horario,
      diasSemana: List<String>.from(diasSelecionados),
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
                  'Pesquisa de Remedios',
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
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value.trim();
                    });
                  },
                  onSubmitted: (_) => _onSearch(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Digite o nome do remedio',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _onSearch,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Buscar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 50),
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
    final resultadosBusca = _filtrarCatalogo(_catalogoFake);
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
          child: ListView(
            children: [
              const Text(
                'Meus Remedios',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${_medicamentosSalvos.length} item(ns) salvo(s)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_medicamentosSalvos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: const Text(
                    'Voce ainda nao adicionou remedios na lista inicial.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ..._medicamentosSalvos.map(
                  (item) => MedicamentoItemCard(
                    nome: item.nome,
                    quantidade: item.dose,
                    hora: item.horario,
                    data: dataHoje,
                    diasSemana: _formatarDiasSemana(item.diasSemana),
                    imageUrl: null,
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              const Text(
                'Resultado da Pesquisa',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (_searchTerm.isEmpty)
                const Text(
                  'Digite e busque um remedio para ver resultados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else if (resultadosBusca.isEmpty)
                Text(
                  'Nenhum remedio encontrado para "$_searchTerm".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                )
              else
                ...resultadosBusca.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.medication_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dose padrao: ${item.dosePadrao} | Hora: ${item.horarioPadrao}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 110,
                          child: ElevatedButton(
                            onPressed: () => _abrirDialogoAdicionar(item),
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchTerm = _searchController.text.trim();
    });
  }

  List<_MedicamentoCatalogo> _filtrarCatalogo(
    List<_MedicamentoCatalogo> itens,
  ) {
    if (_searchTerm.isEmpty) {
      return const [];
    }

    final termo = _normalizarTexto(_searchTerm);
    return itens
        .where((item) => _normalizarTexto(item.nome).contains(termo))
        .toList();
  }

  String _normalizarTexto(String texto) {
    const mapa = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ç': 'c',
    };

    var normalizado = texto.toLowerCase().trim();
    mapa.forEach((comAcento, semAcento) {
      normalizado = normalizado.replaceAll(comAcento, semAcento);
    });
    return normalizado;
  }

  String _formatarDiasSemana(List<String> dias) {
    if (dias.isEmpty) {
      return 'Dias nao definidos';
    }
    return dias.join(', ');
  }

  String _chavesDiasSemana(List<String> dias) {
    final ordenado = List<String>.from(dias)..sort();
    return ordenado.join('|');
  }

  String _formatarData(DateTime date) {
    final dia = date.day.toString().padLeft(2, '0');
    final mes = date.month.toString().padLeft(2, '0');
    final ano = date.year.toString();
    return '$dia/$mes/$ano';
  }
}

class _MedicamentoCatalogo {
  final String nome;
  final String dosePadrao;
  final String horarioPadrao;

  const _MedicamentoCatalogo({
    required this.nome,
    required this.dosePadrao,
    required this.horarioPadrao,
  });
}
