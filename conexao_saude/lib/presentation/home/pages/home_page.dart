import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:conexao_saude/presentation/home/widgets/medicamento_item_card.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<_MedicamentoDisplay> _medicamentosFake = [
    _MedicamentoDisplay(
      nome: 'Dipirona',
      quantidade: '1 comprimido',
      hora: '08:00',
      data: '06/04/2026',
      imageUrl: null,
    ),
    _MedicamentoDisplay(
      nome: 'Vitamina D',
      quantidade: '2 gotas',
      hora: '12:30',
      data: '06/04/2026',
      imageUrl: null,
    ),
    _MedicamentoDisplay(
      nome: 'Losartana',
      quantidade: '1 comprimido',
      hora: '20:00',
      data: '06/04/2026',
      imageUrl: null,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final medicamentos = _filtrarMedicamentos(_medicamentosFake);

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
                'Lista de Remedios',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${medicamentos.length} item(ns)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (medicamentos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
                  ),
                  child: Text(
                    _searchTerm.isEmpty
                        ? 'Nenhum remedio encontrado para teste.'
                        : 'Nenhum remedio encontrado para "$_searchTerm".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...medicamentos.map(
                  (item) => MedicamentoItemCard(
                    nome: item.nome,
                    quantidade: item.quantidade,
                    hora: item.hora,
                    data: item.data,
                    imageUrl: item.imageUrl,
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

  List<_MedicamentoDisplay> _filtrarMedicamentos(List<_MedicamentoDisplay> itens) {
    if (_searchTerm.isEmpty) {
      return itens;
    }

    final termo = _searchTerm.toLowerCase();
    return itens.where((item) => item.nome.toLowerCase().contains(termo)).toList();
  }
}

class _MedicamentoDisplay {
  final String nome;
  final String quantidade;
  final String hora;
  final String data;
  final String? imageUrl;

  const _MedicamentoDisplay({
    required this.nome,
    required this.quantidade,
    required this.hora,
    required this.data,
    required this.imageUrl,
  });
}