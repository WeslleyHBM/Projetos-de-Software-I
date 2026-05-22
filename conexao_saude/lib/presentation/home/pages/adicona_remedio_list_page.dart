import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:conexao_saude/core/services/notification_service.dart';
import 'package:conexao_saude/data/models/lista_medicamento_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AdicionaRemedioListPage extends StatefulWidget {
  const AdicionaRemedioListPage({super.key});

  @override
  State<AdicionaRemedioListPage> createState() => _AdicionaRemedioListPageState();
}

class _AdicionaRemedioListPageState extends State<AdicionaRemedioListPage> {
  static const String _listaHomeKey = 'lista_home_inicial';
  static const String _colecaoRemume = 'remume_santa_maria';

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchTerm = '';
  List<_MedicamentoCatalogoFirestore> _resultadosPesquisa = [];
  bool _isSearching = false;
  String? _searchError;
  final _notificationService = NotificationService();

  Box<ListaMedicamentoModel> get _listasBox =>
      Hive.box<ListaMedicamentoModel>('minhas_listas');

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _adicionarMedicamentoNoHive({
    required String nome,
    required String dose,
    required String horario,
    required DateTime dataInicio,
    required DateTime dataFim,
    required int intervaloHoras,
  }) async {
    final listaAtual = _listasBox.get(_listaHomeKey);
    final medicamentos = listaAtual == null
        ? <MedicamentoModel>[]
        : List<MedicamentoModel>.from(listaAtual.medicamentos);

    final jaExiste = medicamentos.any(
      (item) =>
          item.nome.toLowerCase() == nome.toLowerCase() &&
          item.dose.toLowerCase() == dose.toLowerCase() &&
          item.horario == horario
    );

    if (jaExiste) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esse remédio já foi adicionado na receita.')),
      );
      return;
    }

    final novoMedicamento = MedicamentoModel(
      nome: nome,
      dose: dose,
      horario: horario,
      dataInicio: dataInicio,
      dataFim: dataFim,
      intervaloHoras: intervaloHoras,
    );

    medicamentos.add(novoMedicamento);

    await _listasBox.put(
      _listaHomeKey,
      ListaMedicamentoModel(
        titulo: 'Lista inicial',
        medicamentos: medicamentos,
      ),
    );

    // Agenda as notificações (Lógica limpa sem o bug dos diasSemana)
    await _notificationService.agendarNotificacoesRecorrentes(
      medicamentoId: medicamentos.indexOf(novoMedicamento),
      medicamentoNome: nome,
      dose: dose,
      horario: horario,
      diasSemana: const [],
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nome adicionado na receita do paciente.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _abrirDialogoAdicionar(_MedicamentoCatalogoFirestore item) async {
    final doseController = TextEditingController(
      text: item.concentracao.isNotEmpty ? item.concentracao : '1 comprimido',
    );
    DateTime horarioSelecionado = DateTime(2026, 1, 1, 8, 0);
    DateTime dataInicio = DateTime.now();
    DateTime dataFim = DateTime.now().add(const Duration(days: 30));
    int intervaloHoras = 8;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adicionar ${item.nome}'),
          // O SizedBox abaixo é o escudo que impede o travamento de tela
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
                              firstDate: DateTime.now(),
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
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) return;

    final dose = doseController.text.trim();
    final String horario = '${horarioSelecionado.hour.toString().padLeft(2, '0')}:${horarioSelecionado.minute.toString().padLeft(2, '0')}';

    if (dose.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a dose para adicionar.')),
      );
      return;
    }

    await _adicionarMedicamentoNoHive(
      nome: item.nome,
      dose: dose,
      horario: horario,
      dataInicio: dataInicio,
      dataFim: dataFim,
      intervaloHoras: intervaloHoras,
    );
  }

  String _formatarData(DateTime date) {
    final dia = date.day.toString().padLeft(2, '0');
    final mes = date.month.toString().padLeft(2, '0');
    final ano = date.year.toString();
    return '$dia/$mes/$ano';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Catálogo Remume'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                  'Pesquisar no Banco Online',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
                    hintText: 'Digite o nome do remédio',
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
                'Resultado da Pesquisa',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (_searchTerm.isEmpty)
                const Text(
                  'Digite e busque um remédio para ver os resultados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else if (_isSearching)
                const Center(child: CircularProgressIndicator())
              else if (_searchError != null)
                Text(
                  _searchError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                )
              else if (_resultadosPesquisa.isEmpty)
                Text(
                  'Nenhum remédio encontrado para "$_searchTerm".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                )
              else
                ..._resultadosPesquisa.map(
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
                                'Concentração: ${item.concentracao} | Forma: ${item.formaFarmaceutica}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Componente: ${item.componente}',
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
    _buscarMedicamentosFirestore();
  }

  void _onSearchChanged(String value) {
    final termo = value.trim();

    setState(() {
      _searchTerm = termo;
    });

    _searchDebounce?.cancel();

    if (termo.isEmpty) {
      setState(() {
        _resultadosPesquisa = [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _buscarMedicamentosFirestore();
    });
  }

  Future<void> _buscarMedicamentosFirestore() async {
    final termo = _searchController.text.trim();

    if (termo.isEmpty) {
      setState(() {
        _searchTerm = '';
        _resultadosPesquisa = [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _searchTerm = termo;
      _isSearching = true;
      _searchError = null;
      _resultadosPesquisa = [];
    });

    try {
      final termoNormalizado = _normalizarTexto(termo);
      final collection = FirebaseFirestore.instance.collection(_colecaoRemume);

      final consultas = await Future.wait([
        collection
            .orderBy('nomeNormalizado')
            .startAt([termoNormalizado])
            .endAt(['$termoNormalizado\uf8ff'])
            .get(),
        collection
            .orderBy('componenteNormalizado')
            .startAt([termoNormalizado])
            .endAt(['$termoNormalizado\uf8ff'])
            .get(),
      ]);

      final resultadosPorId = <String, _MedicamentoCatalogoFirestore>{};

      for (final snapshot in consultas) {
        for (final doc in snapshot.docs) {
          final item = _MedicamentoCatalogoFirestore.fromFirestore(doc.id, doc.data());
          resultadosPorId[doc.id] = item;
        }
      }

      if (resultadosPorId.isEmpty) {
        final fallbackSnapshot = await collection.get();
        for (final doc in fallbackSnapshot.docs) {
          final item = _MedicamentoCatalogoFirestore.fromFirestore(doc.id, doc.data());
          final nomeNormalizado = _normalizarTexto(item.nome);
          final componenteNormalizado = _normalizarTexto(item.componente);
          if (nomeNormalizado.contains(termoNormalizado) ||
              componenteNormalizado.contains(termoNormalizado)) {
            resultadosPorId[doc.id] = item;
          }
        }
      }

      final resultadosOrdenados = resultadosPorId.values.toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));

      if (!mounted) return;
      setState(() {
        _resultadosPesquisa = resultadosOrdenados;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searchError = _mensagemErroBusca(error);
        _isSearching = false;
      });
    }
  }

  String _mensagemErroBusca(Object error) {
    if (error is FirebaseException &&
        error.plugin == 'cloud_firestore' &&
        error.code == 'permission-denied') {
      return 'Permissão negada no Firestore. Verifique as regras da coleção.';
    }

    return 'Não foi possível consultar o banco de dados: $error';
  }

  String _normalizarTexto(String texto) {
    const mapa = {
      'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'é': 'e', 'ê': 'e',
      'í': 'i', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ç': 'c',
    };

    var normalizado = texto.toLowerCase().trim();
    mapa.forEach((comAcento, semAcento) {
      normalizado = normalizado.replaceAll(comAcento, semAcento);
    });

    normalizado = normalizado.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return normalizado
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

class _MedicamentoCatalogoFirestore {
  final String nome;
  final String concentracao;
  final String formaFarmaceutica;
  final String componente;
  final String nomeNormalizado;
  final String componenteNormalizado;

  const _MedicamentoCatalogoFirestore({
    required this.nome,
    required this.concentracao,
    required this.formaFarmaceutica,
    required this.componente,
    required this.nomeNormalizado,
    required this.componenteNormalizado,
  });

  factory _MedicamentoCatalogoFirestore.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final nome = (data['nome'] as String? ?? id).trim();
    final concentracao = (data['concentracao'] as String? ?? '').trim();
    final formaFarmaceutica = (data['formaFarmaceutica'] as String? ?? '').trim();
    final componente = (data['componente'] as String? ?? '').trim();
    final nomeNormalizado = (data['nomeNormalizado'] as String? ?? nome).trim();
    final componenteNormalizado =
        (data['componenteNormalizado'] as String? ?? componente).trim();

    return _MedicamentoCatalogoFirestore(
      nome: nome,
      concentracao: concentracao.isEmpty ? 'Não informado' : concentracao,
      formaFarmaceutica:
          formaFarmaceutica.isEmpty ? 'Não informado' : formaFarmaceutica,
      componente: componente.isEmpty ? 'Não informado' : componente,
      nomeNormalizado: nomeNormalizado.isEmpty
          ? _normalizarTextoFirestore(nome)
          : nomeNormalizado,
      componenteNormalizado: componenteNormalizado.isEmpty
          ? _normalizarTextoFirestore(componente)
          : componenteNormalizado,
    );
  }
}

String _normalizarTextoFirestore(String texto) {
  const mapa = {
    'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'é': 'e', 'ê': 'e',
    'í': 'i', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ç': 'c',
  };

  var normalizado = texto.toLowerCase().trim();
  mapa.forEach((comAcento, semAcento) {
    normalizado = normalizado.replaceAll(comAcento, semAcento);
  });

  normalizado = normalizado.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return normalizado
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}