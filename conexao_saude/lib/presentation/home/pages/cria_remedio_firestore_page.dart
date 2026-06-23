import 'dart:io' show File;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:conexao_saude/data/models/medicamento_firestore_model.dart';

class CriaRemediaFirestorePage extends StatefulWidget {
  const CriaRemediaFirestorePage({super.key});

  @override
  State<CriaRemediaFirestorePage> createState() => _CriaRemediaFirestorePageState();
}

class _CriaRemediaFirestorePageState extends State<CriaRemediaFirestorePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _concentracaoController = TextEditingController();
  final _formulaController = TextEditingController();
  final _componenteBasicoController = TextEditingController();

  List<XFile> _imagensSelecionadas = []; 
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nomeController.dispose(); _concentracaoController.dispose();
    _formulaController.dispose(); _componenteBasicoController.dispose();
    super.dispose();
  }

  Future<void> _escolherImagens() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70); 
    if (pickedFiles.isNotEmpty) setState(() => _imagensSelecionadas.addAll(pickedFiles));
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

  Future<void> _salvarMedicamento() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      List<String> linksDasFotos = [];
      
      for (var img in _imagensSelecionadas) {
        String? link = await _uploadParaCloudinary(img);
        if (link != null) linksDasFotos.add(link);
      }

      final agora = DateTime.now();
      final novoMedicamento = MedicamentoFirestoreModel(
        id: '', nome: _nomeController.text.trim(), concentracao: _concentracaoController.text.trim(),
        formula: _formulaController.text.trim(), componenteBasico: _componenteBasicoController.text.trim(),
        dataCriacao: agora, dataAtualizacao: agora,
        imageUrls: linksDasFotos, 
      );

      await _firestore.collection('remume_santa_maria').add(novoMedicamento.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${novoMedicamento.nome} adicionado!'), backgroundColor: Colors.green));
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
      appBar: AppBar(title: const Text('Novo Medicamento'), centerTitle: true, backgroundColor: AppColors.primary, elevation: 0),
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
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.add_a_photo, size: 30, color: AppColors.primary), Text('Adicionar', style: TextStyle(color: AppColors.primary))],
                        ),
                      ),
                    ),
                    ..._imagensSelecionadas.asMap().entries.map((entry) {
                      return Container(
                        width: 120, margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: kIsWeb 
                                  ? Image.network(entry.value.path, width: 120, height: 120, fit: BoxFit.cover)
                                  : Image.file(File(entry.value.path), width: 120, height: 120, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _imagensSelecionadas.removeAt(entry.key)),
                                child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
                  Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _salvarMedicamento, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Adicionar', style: TextStyle(color: Colors.white)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}