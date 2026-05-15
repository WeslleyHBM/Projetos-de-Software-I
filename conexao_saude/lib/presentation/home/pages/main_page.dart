import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:conexao_saude/presentation/home/pages/home_page.dart';
import 'package:conexao_saude/presentation/home/pages/estatisticas_page.dart';
import 'package:conexao_saude/presentation/home/pages/admin_page.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Essa variável guarda qual aba está selecionada no momento. Começa no 0 (Início).
  int _indiceAtual = 0;

  // Essa é a lista das páginas que o aplicativo tem. 
  // Agora temos apenas 2 páginas na base (0 e 1)
  final List<Widget> _paginas = [
    const HomePage(),
    const EstatisticasPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos um Stack (Pilha) para colocar a engrenagem por cima de tudo
      body: Stack(
        children: [
          // 1º Camada: A página atual (Início ou Estatísticas)
          _paginas[_indiceAtual],
          
          // 2º Camada: O botão da engrenagem flutuando na esquerda
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft, // Posiciona no topo esquerdo
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.settings, size: 30, color: Colors.white),
                  onPressed: () {
                    // Ao invés de trocar a aba, abrimos a tela do médico por cima
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminPage(), // <-- Mude para MedicoPage() se esse for o nome da sua classe
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      
      // A barra inferior agora só tem 2 itens
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (indiceClicado) {
          setState(() {
            _indiceAtual = indiceClicado;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estatísticas',
          ),
        ],
      ),
    );
  }
}