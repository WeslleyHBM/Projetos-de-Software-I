import 'dart:io' show File;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:conexao_saude/data/models/medicamento_firestore_model.dart';

class EditaCatalogoPage extends StatefulWidget {
  const EditaCatalogoPage({super.key});
  @override
  State<EditaCatalogoPage> createState() => _EditaCatalogoPageState();
}

class _EditaCatalogoPageState extends State<EditaCatalogoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController? _searchControllerInstance;
  String _searchQuery = '';
  late Future<bool> _authFuture;

  TextEditingController get _searchController { _searchControllerInstance ??= TextEditingController(); return _searchControllerInstance!; }

  @override
  void initState() { super.initState(); _authFuture = _waitForAuth(); }
  @override
  void dispose() { _searchControllerInstance?.dispose(); super.dispose(); }

  bool _matchesSearch(MedicamentoFirestoreModel medicamento) {
    if (_searchQuery.isEmpty) return true;
    return medicamento.nome.toLowerCase().contains(_searchQuery) || medicamento.concentracao.toLowerCase().contains(_searchQuery) || medicamento.formula.toLowerCase().contains(_searchQuery) || medicamento.componenteBasico.toLowerCase().contains(_searchQuery);
  }

  Future<void> _abrirPaginaEditar(MedicamentoFirestoreModel medicamento) async {
    final resultado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => EditaMedicamentoFirestorePage(medicamento: medicamento)));
    if (resultado == true && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicamento atualizado!'), backgroundColor: Colors.green));
  }

  Future<void> _confirmarDeletar(MedicamentoFirestoreModel medicamento) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deletar Medicamento'), content: Text('Tem certeza que deseja deletar "${medicamento.nome}"?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(icon: const Icon(Icons.delete), label: const Text('Deletar'), onPressed: () { Navigator.of(dialogContext).pop(); _deletarMedicamento(medicamento); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _deletarMedicamento(MedicamentoFirestoreModel medicamento) async {
    try {
      await _firestore.collection('remume_santa_maria').doc(medicamento.id).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${medicamento.nome} deletado!'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    }
  }

  Future<bool> _waitForAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return true;
    for (int i = 0; i < 50; i++) { await Future.delayed(const Duration(milliseconds: 100)); if (auth.currentUser != null) return true; }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Catálogo'), centerTitle: true, backgroundColor: AppColors.primary, elevation: 0),
      body: FutureBuilder<bool>(
        future: _authFuture,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Carregando...')]));
          final authOk = authSnapshot.data ?? false;

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController, textInputAction: TextInputAction.none, onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(hintText: 'Pesquisar...', prefixIcon: const Icon(Icons.search), suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('remume_santa_maria').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return const Center(child: Text('Erro ao carregar.'));
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Nenhum medicamento.'));

                        final medicamentos = snapshot.data!.docs.map((doc) => MedicamentoFirestoreModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
                        final medicamentosFiltrados = medicamentos.where(_matchesSearch).toList();

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: medicamentosFiltrados.length,
                          itemBuilder: (context, index) {
                            final medicamento = medicamentosFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 60, height: 60, clipBehavior: Clip.hardEdge, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: medicamento.imageUrls.isNotEmpty ? Image.network(medicamento.imageUrls.first, fit: BoxFit.cover) : const Icon(Icons.medication_liquid, color: AppColors.primary),
                                ),
                                title: Text(medicamento.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 8), Text('Concentração: ${medicamento.concentracao}', style: const TextStyle(fontSize: 12))]),
                                trailing: SizedBox(width: 100, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _abrirPaginaEditar(medicamento)), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmarDeletar(medicamento))])),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (!authOk) Positioned(top: 0, left: 0, right: 0, child: Container(color: Colors.orange.withValues(alpha: 0.3), padding: const EdgeInsets.all(12), child: const Text('Modo offline', style: TextStyle(fontSize: 13, color: Colors.orange)))),
            ],
          );
        },
      ),
    );
  }
}

// ============= PÁGINA DE EDIÇÃO =============
class EditaMedicamentoFirestorePage extends StatefulWidget {
  final MedicamentoFirestoreModel medicamento;
  const EditaMedicamentoFirestorePage({super.key, required this.medicamento});
  @override
  State<EditaMedicamentoFirestorePage> createState() => _EditaMedicamentoFirestorePageState();
}

class _EditaMedicamentoFirestorePageState extends State<EditaMedicamentoFirestorePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _concentracaoController;
  late TextEditingController _formulaController;
  late TextEditingController _componenteBasicoController;

  List<String> _imagensAntigas = [];
  List<XFile> _novasImagens = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.medicamento.nome);
    _concentracaoController = TextEditingController(text: widget.medicamento.concentracao);
    _formulaController = TextEditingController(text: widget.medicamento.formula);
    _componenteBasicoController = TextEditingController(text: widget.medicamento.componenteBasico);
    _imagensAntigas = List.from(widget.medicamento.imageUrls);
  }

  @override
  void dispose() { _nomeController.dispose(); _concentracaoController.dispose(); _formulaController.dispose(); _componenteBasicoController.dispose(); super.dispose(); }

  Future<void> _escolherImagens() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) setState(() => _novasImagens.addAll(pickedFiles));
  }

  Future<String?> _uploadParaCloudinary(XFile imagem) async {
    const cloudName = 'dzibeh8rv'; 
    const uploadPreset = 'conexao_saude';  // <<< COLOQUE O SEU PRESET AQUI

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)..fields['upload_preset'] = uploadPreset;
    
    final bytes = await imagem.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: imagem.name));

    final response = await request.send();
    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(await response.stream.bytesToString());
      return jsonMap['secure_url']; 
    }
    return null;
  }

  Future<void> _salvarEdicoes() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      List<String> linksFinais = List.from(_imagensAntigas);

      for (var img in _novasImagens) {
        String? link = await _uploadParaCloudinary(img);
        if (link != null) linksFinais.add(link);
      }

      final medicamentoAtualizado = widget.medicamento.copyWith(
        nome: _nomeController.text.trim(), concentracao: _concentracaoController.text.trim(),
        formula: _formulaController.text.trim(), componenteBasico: _componenteBasicoController.text.trim(),
        dataAtualizacao: DateTime.now(),
        imageUrls: linksFinais, 
      );

      await _firestore.collection('remume_santa_maria').doc(widget.medicamento.id).update(medicamentoAtualizado.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${medicamentoAtualizado.nome} atualizado!'), backgroundColor: Colors.green));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Medicamento'), centerTitle: true, backgroundColor: AppColors.primary, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: _escolherImagens,
                      child: Container(
                        width: 120, margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 30, color: AppColors.primary), Text('Adicionar', style: TextStyle(color: AppColors.primary))]),
                      ),
                    ),
                    ..._imagensAntigas.asMap().entries.map((entry) => Container(width: 120, margin: const EdgeInsets.only(right: 12), child: Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(entry.value, width: 120, height: 120, fit: BoxFit.cover)), Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _imagensAntigas.removeAt(entry.key)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white))))]))),
                    ..._novasImagens.asMap().entries.map((entry) => Container(width: 120, margin: const EdgeInsets.only(right: 12), child: Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(16), child: kIsWeb ? Image.network(entry.value.path, width: 120, height: 120, fit: BoxFit.cover) : Image.file(File(entry.value.path), width: 120, height: 120, fit: BoxFit.cover)), Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _novasImagens.removeAt(entry.key)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white))))]))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Informações do Medicamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              
              TextFormField(controller: _nomeController, decoration: InputDecoration(labelText: 'Nome do Medicamento', prefixIcon: const Icon(Icons.medication), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _concentracaoController, decoration: InputDecoration(labelText: 'Concentração', prefixIcon: const Icon(Icons.info), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
              const SizedBox(height: 16),
              
              // ==========================================================
              // AQUI: A Fórmula agora é OPCIONAL (não tem validador)
              TextFormField(controller: _formulaController, decoration: InputDecoration(labelText: 'Fórmula (Opcional)', prefixIcon: const Icon(Icons.description), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              
              // AQUI: O Componente Básico agora é OPCIONAL (não tem validador)
              TextFormField(controller: _componenteBasicoController, decoration: InputDecoration(labelText: 'Componente Básico (Opcional)', prefixIcon: const Icon(Icons.science), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              // ==========================================================
              
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _isLoading ? null : () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Cancelar'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _salvarEdicoes, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Atualizar', style: TextStyle(color: Colors.white)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}