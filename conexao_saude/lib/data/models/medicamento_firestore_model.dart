class MedicamentoFirestoreModel {
  final String id; // ID do Firestore
  final String nome;
  final String concentracao;
  final String formula;
  final String componenteBasico;
  final String? fotoUrl;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;

  MedicamentoFirestoreModel({
    required this.id,
    required this.nome,
    required this.concentracao,
    required this.formula,
    required this.componenteBasico,
    this.fotoUrl,
    required this.dataCriacao,
    required this.dataAtualizacao,
  });

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'concentracao': concentracao,
      'formula': formula,
      'componenteBasico': componenteBasico,
      'fotoUrl': fotoUrl,
      'dataCriacao': dataCriacao,
      'dataAtualizacao': dataAtualizacao,
    };
  }

  // Converter de Map do Firestore
  factory MedicamentoFirestoreModel.fromMap(String id, Map<String, dynamic> data) {
    return MedicamentoFirestoreModel(
      id: id,
      nome: data['nome'] ?? '',
      concentracao: data['concentracao'] ?? '',
      formula: data['formula'] ?? '',
      componenteBasico: data['componenteBasico'] ?? '',
      fotoUrl: data['fotoUrl'],
      dataCriacao: (data['dataCriacao'] as dynamic)?.toDate() ?? DateTime.now(),
      dataAtualizacao: (data['dataAtualizacao'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // Copiar com mudanças
  MedicamentoFirestoreModel copyWith({
    String? id,
    String? nome,
    String? concentracao,
    String? formula,
    String? componenteBasico,
    String? fotoUrl,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return MedicamentoFirestoreModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      concentracao: concentracao ?? this.concentracao,
      formula: formula ?? this.formula,
      componenteBasico: componenteBasico ?? this.componenteBasico,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
