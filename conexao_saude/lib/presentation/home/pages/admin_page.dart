import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:conexao_saude/presentation/home/pages/adicona_remedio_list_page.dart'; // Ajuste o caminho se necessário
import 'package:conexao_saude/data/models/lista_medicamento_model.dart';
import 'package:conexao_saude/presentation/home/pages/cria_remedio_firestore_page.dart';
import 'package:conexao_saude/presentation/home/pages/edita_catalogo_page.dart'; 

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {

  // --- FUNÇÃO MÁGICA QUE GERA E ABRE O PDF PARA DOWNLOAD ---
  Future<void> _gerarEBaixarPDF(BuildContext context) async {
    final pdf = pw.Document();
    
    // Abre a caixa do Hive onde os medicamentos do paciente estão salvos
    final box = await Hive.openBox<ListaMedicamentoModel>('minhas_listas'); 
    final listaAtual = box.get('lista_home_inicial');
    
    if (listaAtual == null || listaAtual.medicamentos.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O paciente não possui medicamentos na lista para exportar.')),
      );
      return;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('Conexão Saúde - Receita Digital', 
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('Checklist de Consumo de Medicamentos', 
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
            ]
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Documento gerado eletronicamente pelo Painel do Médico. Página ${context.pageNumber} de ${context.pagesCount}', 
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ]
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> elementosPDF = []; 

          for (var item in listaAtual.medicamentos) {
            final partesHora = item.horario.split(':');
            final int horaBase = int.tryParse(partesHora[0]) ?? 0;
            final int minutoBase = int.tryParse(partesHora[1]) ?? 0;

            DateTime doseAtual = DateTime(
              item.dataInicio.year,
              item.dataInicio.month,
              item.dataInicio.day,
              horaBase,
              minutoBase,
            );

            final int intervalo = item.intervaloHoras > 0 ? item.intervaloHoras : 8;
            List<DateTime> todasAsDoses = [];
            
            int limiteDoses = 0;
            while (doseAtual.isBefore(item.dataFim) && limiteDoses < 200) {
              todasAsDoses.add(doseAtual);
              doseAtual = doseAtual.add(Duration(hours: intervalo));
              limiteDoses++;
            }

            // 1. Título do Remédio
            elementosPDF.add(
              pw.Text(
                item.nome.toUpperCase(), 
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)
              )
            );
            elementosPDF.add(pw.SizedBox(height: 4));
            
            // 2. Dose e Intervalo
            elementosPDF.add(
              pw.Text(
                'Dose: ${item.dose}   |   De ${intervalo} em ${intervalo} horas', 
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey800)
              )
            );
            elementosPDF.add(pw.SizedBox(height: 16));

            // =================================================================
            // NOVA SECÇÃO: LINHAS PARA OBSERVAÇÕES MÉDICAS
            // =================================================================
            elementosPDF.add(
              pw.Text(
                'Observações:', 
                style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)
              )
            );
            elementosPDF.add(pw.SizedBox(height: 6));
            
            // Desenha 3 linhas seguidas com espaçamento
            for (int k = 0; k < 3; k++) {
              elementosPDF.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 14),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey400, width: 1) // Desenha só a linha de baixo
                    )
                  ),
                )
              );
            }
            elementosPDF.add(pw.SizedBox(height: 12));
            // =================================================================

            // 3. Linhas da Grelha de Quadradinhos
            const int numeroDeColunas = 3; 

            for (int i = 0; i < todasAsDoses.length; i += numeroDeColunas) {
              final chunk = todasAsDoses.sublist(
                i, 
                i + numeroDeColunas > todasAsDoses.length ? todasAsDoses.length : i + numeroDeColunas
              );
              
              elementosPDF.add(
                pw.Row(
                  children: List.generate(numeroDeColunas, (index) {
                    if (index < chunk.length) {
                      final dose = chunk[index];
                      final horaStr = dose.hour.toString().padLeft(2, '0');
                      final minStr = dose.minute.toString().padLeft(2, '0');
                      final diaStr = dose.day.toString().padLeft(2, '0');
                      final mesStr = dose.month.toString().padLeft(2, '0');
                      
                      return pw.Expanded(
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 14, 
                              height: 14, 
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black, width: 1.2),
                              )
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text('$horaStr:$minStr  $diaStr/$mesStr', style: const pw.TextStyle(fontSize: 13)),
                          ]
                        )
                      );
                    } else {
                      return pw.Expanded(child: pw.SizedBox());
                    }
                  })
                )
              );
              elementosPDF.add(pw.SizedBox(height: 12)); 
            }
            
            // 4. Espaçamento e Linha divisória antes do próximo remédio
            elementosPDF.add(pw.SizedBox(height: 8));
            elementosPDF.add(pw.Divider(color: PdfColors.grey400, thickness: 1));
            elementosPDF.add(pw.SizedBox(height: 24)); 
          }

          return elementosPDF;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receita_Checklist_Paciente.pdf',
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
        child: SingleChildScrollView( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'O que você deseja fazer?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // CARD 1: Adicionar/Remover do Paciente 
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
                onTap: () async {
                  final resultado = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CriaRemediaFirestorePage(),
                    ),
                  );

                  if (resultado == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Medicamento adicionado ao catálogo com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // CARD 3: Editar Banco de Dados
              _AdminActionCard(
                titulo: 'Editar Catálogo',
                subtitulo: 'Mudar nome, dose e descrição dos remédios.',
                icone: Icons.edit_document,
                cor: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditaCatalogoPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // CARD 4: EXPORTAR PDF
              _AdminActionCard(
                titulo: 'Exportar Receita em PDF',
                subtitulo: 'Gerar arquivo PDF com doses e horários para baixar.',
                icone: Icons.picture_as_pdf,
                cor: Colors.red,
                onTap: () => _gerarEBaixarPDF(context), 
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