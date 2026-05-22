import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:conexao_saude/presentation/home/pages/adicona_remedio_list_page.dart'; // Ajuste o caminho se necessário
import 'package:conexao_saude/data/models/lista_medicamento_model.dart'; 

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  // --- FUNÇÃO MÁGICA QUE GERA E ABRE O PDF PARA DOWNLOAD ---
  Future<void> _gerarEBaixarPDF(BuildContext context) async {
    final pdf = pw.Document();
    
    // Abre a caixa do Hive onde os medicamentos do paciente estão salvos
    final box = await Hive.openBox<ListaMedicamentoModel>('minhas_listas'); 
    final listaAtual = box.get('lista_home_inicial');
    
    if (listaAtual == null || listaAtual.medicamentos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O paciente não possui medicamentos na lista para exportar.')),
      );
      return;
    }

    // Desenha o visual do PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('Conexão Saúde - Receita Digital', 
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text('Lista de Medicamentos e Orientações de Consumo', 
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)), // Retirado o const
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // Lista os remédios um embaixo do outro no PDF
                pw.ListView.builder(
                  itemCount: listaAtual.medicamentos.length,
                  itemBuilder: (pw.Context context, int index) {
                    final item = listaAtual.medicamentos[index];
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 16),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 1),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.nome, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // CORRIGIDO AQUI!
                            children: [
                              pw.Text('Dose: ${item.dose}', style: pw.TextStyle(fontSize: 14)), // Retirado o const
                              pw.Text('Intervalo: De ${item.intervaloHoras} em ${item.intervaloHoras} horas', 
                                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Horário da primeira dose: ${item.horario}',
                            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600) // Retirado o const
                          ),
                        ],
                      ),
                    );
                  },
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('Documento gerado eletronicamente pelo Painel do Médico.', 
                      style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)), // CORRIGIDO AQUI!
                ),
              ],
            ),
          );
        },
      ),
    );

    // Abre a tela nativa do telemóvel
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receita_Medicamentos_Paciente.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Médico'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Adicionado para dar scroll caso a tela seja pequena
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'O que você deseja fazer?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // CARD 1: Adicionar/Remover do Paciente (Toda a lógica antiga de adicionar do catálogo vem pra cá!)
              _AdminActionCard(
                titulo: 'Receita do Paciente',
                subtitulo: 'Adicionar ou remover remédios da rotina diária.',
                icone: Icons.assignment_ind,
                cor: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdicionaRemedioListPage()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // CARD 2: Criar Novo Remédio no Banco
              _AdminActionCard(
                titulo: 'Novo Medicamento',
                subtitulo: 'Cadastrar um remédio novo no banco de dados.',
                icone: Icons.add_box,
                cor: Colors.green,
                onTap: () {
                  print('Clicou em Novo Medicamento');
                },
              ),
              const SizedBox(height: 16),

              // CARD 3: Editar Banco de Dados
              _AdminActionCard(
                titulo: 'Editar Catálogo',
                subtitulo: 'Mudar nome, dose e adicionar foto aos remédios.',
                icone: Icons.edit_document,
                cor: Colors.orange,
                onTap: () {
                  print('Clicou em Editar Catálogo');
                },
              ),
              const SizedBox(height: 16),

              // CARD 4: NOVO CARD DE EXPORTAR PDF
              _AdminActionCard(
                titulo: 'Exportar Receita em PDF',
                subtitulo: 'Gerar arquivo PDF com doses e horários para baixar.',
                icone: Icons.picture_as_pdf,
                cor: Colors.red,
                onTap: () => _gerarEBaixarPDF(context), // Ativa a função do PDF
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 32, color: cor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitulo, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}