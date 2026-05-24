import 'package:flutter/material.dart';
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

  Future<void> _abrirPaginaEditar(
    MedicamentoFirestoreModel medicamento,
  ) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditaMedicamentoFirestorePage(
          medicamento: medicamento,
        ),
      ),
    );

    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicamento atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmarDeletar(MedicamentoFirestoreModel medicamento) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deletar Medicamento'),
        content: Text(
          'Tem certeza que deseja deletar "${medicamento.nome}" do catálogo?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Deletar'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deletarMedicamento(medicamento);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletarMedicamento(MedicamentoFirestoreModel medicamento) async {
    try {
      await _firestore.collection('remume_santa_maria').doc(medicamento.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicamento.nome} deletado do catálogo!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao deletar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Aguarda a autenticação estar pronta (max 5 segundos)
  // Se falhar, permite continuar mesmo sem auth (Firestore dirá se é permitido)
  Future<bool> _waitForAuth() async {
    final auth = FirebaseAuth.instance;
    
    // Se já está autenticado, retorna verdadeiro
    if (auth.currentUser != null) {
      debugPrint('✓ Usuário já autenticado: ${auth.currentUser?.uid}');
      return true;
    }

    // Se não está, aguarda por até 5 segundos
    debugPrint('⏳ Aguardando autenticação...');
    for (int i = 0; i < 50; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (auth.currentUser != null) {
        debugPrint('✓ Autenticação completada: ${auth.currentUser?.uid}');
        return true;
      }
    }

    // Se chegou aqui, timeout na auth (pode ser web ou config faltando)
    debugPrint('⚠️ Timeout aguardando autenticação (continuando mesmo assim)');
    return false; // Continua mesmo sem auth
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Catálogo'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: FutureBuilder<bool>(
        future: _waitForAuth(),
        builder: (context, authSnapshot) {
          // Aguardando autenticação
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando autenticação...'),
                ],
              ),
            );
          }

          // Se tem erro no FutureBuilder, mostra aviso
          if (authSnapshot.hasError) {
            debugPrint('⚠️ Erro no FutureBuilder de auth: ${authSnapshot.error}');
          }

          // Auth completou (com sucesso ou timeout) - prossegue com o carregamento
          final authOk = authSnapshot.data ?? false;

          return Stack(
            children: [
              // StreamBuilder para carregar medicamentos da coleção compartilhada
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('remume_santa_maria')
                    .snapshots(),
                builder: (context, snapshot) {
                  // Loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Erro - mostrar detalhes para debugar
                  if (snapshot.hasError) {
                    debugPrint('❌ ERRO no StreamBuilder: ${snapshot.error}');
                    debugPrint('❌ StackTrace: ${snapshot.stackTrace}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar medicamentos:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sem dados
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum medicamento no catálogo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Comece criando um novo medicamento',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Lista de medicamentos
                  final medicamentos = snapshot.data!.docs.map((doc) {
                    return MedicamentoFirestoreModel.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: medicamentos.length,
                    itemBuilder: (context, index) {
                      final medicamento = medicamentos[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.medication_liquid,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            medicamento.nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Concentração: ${medicamento.concentracao}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Fórmula: ${medicamento.formula}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Componente: ${medicamento.componenteBasico}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _abrirPaginaEditar(medicamento),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmarDeletar(medicamento),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              
              // Aviso visual se auth não funcionou (banner no topo)
              if (!authOk)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.orange.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(12),
                    child: const Row(
                      children: [
                        Icon(Icons.info, size: 18, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Modo offline: autenticação não configurada',
                            style: TextStyle(fontSize: 13, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

  const EditaMedicamentoFirestorePage({
    super.key,
    required this.medicamento,
  });

  @override
  State<EditaMedicamentoFirestorePage> createState() =>
      _EditaMedicamentoFirestorePageState();
}

class _EditaMedicamentoFirestorePageState
    extends State<EditaMedicamentoFirestorePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _concentracaoController;
  late TextEditingController _formulaController;
  late TextEditingController _componenteBasicoController;

  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.medicamento.nome);
    _concentracaoController =
        TextEditingController(text: widget.medicamento.concentracao);
    _formulaController =
        TextEditingController(text: widget.medicamento.formula);
    _componenteBasicoController =
        TextEditingController(text: widget.medicamento.componenteBasico);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _concentracaoController.dispose();
    _formulaController.dispose();
    _componenteBasicoController.dispose();
    super.dispose();
  }

  Future<void> _salvarEdicoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final medicamentoAtualizado = widget.medicamento.copyWith(
        nome: _nomeController.text.trim(),
        concentracao: _concentracaoController.text.trim(),
        formula: _formulaController.text.trim(),
        componenteBasico: _componenteBasicoController.text.trim(),
        dataAtualizacao: DateTime.now(),
      );

      await _firestore
          .collection('remume_santa_maria')
          .doc(widget.medicamento.id)
          .update(medicamentoAtualizado.toMap());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${medicamentoAtualizado.nome} atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro Firebase: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar medicamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Medicamento'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informações do Medicamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Medicamento',
                  prefixIcon: const Icon(Icons.medication),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do medicamento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Concentração
              TextFormField(
                controller: _concentracaoController,
                decoration: InputDecoration(
                  labelText: 'Concentração (ex: 500mg/mL)',
                  prefixIcon: const Icon(Icons.info),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a concentração';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fórmula
              TextFormField(
                controller: _formulaController,
                decoration: InputDecoration(
                  labelText: 'Fórmula (ex: C₂₁H₃₀N₂O₂)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a fórmula';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Componente básico
              TextFormField(
                controller: _componenteBasicoController,
                decoration: InputDecoration(
                  labelText: 'Componente Básico',
                  prefixIcon: const Icon(Icons.science),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o componente básico';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvarEdicoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Atualizar',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
