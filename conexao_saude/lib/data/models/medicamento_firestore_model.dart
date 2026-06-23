import 'package:cloud_firestore/cloud_firestore.dart';

class MedicamentoFirestoreModel {
  final String id;
  final String nome;
  final String concentracao;
  final String formula;
  final String componenteBasico;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final List<String> imageUrls; // AGORA É UMA LISTA!

  MedicamentoFirestoreModel({
    required this.id,
    required this.nome,
    required this.concentracao,
    required this.formula,
    required this.componenteBasico,
    required this.dataCriacao,
    required this.dataAtualizacao,
    this.imageUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'concentracao': concentracao,
      'formula': formula,
      'componenteBasico': componenteBasico,
      'dataCriacao': dataCriacao, // O Firebase converte automaticamente para Timestamp
      'dataAtualizacao': dataAtualizacao,
      'imageUrls': imageUrls, 
    };
  }

  factory MedicamentoFirestoreModel.fromMap(String id, Map<String, dynamic> map) {
    // ESTA É A MÁGICA QUE RESOLVE O ERRO VERMELHO DO TIMESTAMP:
    DateTime parseDate(dynamic dateData) {
      if (dateData is Timestamp) return dateData.toDate();
      if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
      return DateTime.now();
    }

    // Preparado para a lista nova, mas aceita a imagem velha se existir
    List<String> urls = [];
    if (map['imageUrls'] != null) {
      urls = List<String>.from(map['imageUrls']);
    } else if (map['imageUrl'] != null) {
      urls = [map['imageUrl'] as String];
    }

    return MedicamentoFirestoreModel(
      id: id,
      nome: map['nome'] ?? '',
      concentracao: map['concentracao'] ?? '',
      formula: map['formula'] ?? '',
      componenteBasico: map['componenteBasico'] ?? '',
      dataCriacao: parseDate(map['dataCriacao']),
      dataAtualizacao: parseDate(map['dataAtualizacao']),
      imageUrls: urls,
    );
  }

  MedicamentoFirestoreModel copyWith({
    String? nome,
    String? concentracao,
    String? formula,
    String? componenteBasico,
    DateTime? dataAtualizacao,
    List<String>? imageUrls,
  }) {
    return MedicamentoFirestoreModel(
      id: id,
      nome: nome ?? this.nome,
      concentracao: concentracao ?? this.concentracao,
      formula: formula ?? this.formula,
      componenteBasico: componenteBasico ?? this.componenteBasico,
      dataCriacao: dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}