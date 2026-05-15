import 'package:flutter/material.dart';
import 'package:conexao_saude/core/theme/app_colors.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A AppBar automaticamente cria o botão de voltar (uma seta)
      appBar: AppBar(
        title: const Text('Área do Médico'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white, // Cor da seta e do título
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Esse é o comando que "fecha" a tela atual e volta para a anterior
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text('Aqui você vai colocar as ferramentas do médico.'),
      ),
    );
  }
}