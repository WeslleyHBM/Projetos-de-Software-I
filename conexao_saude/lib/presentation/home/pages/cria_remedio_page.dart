import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:conexao_saude/data/models/lista_medicamento_model.dart';
import 'package:conexao_saude/core/theme/app_colors.dart';

class CriaRemediaPage extends StatefulWidget {
  const CriaRemediaPage({super.key});

  @override
  State<CriaRemediaPage> createState() => _CriaRemediaPageState();
}

class _CriaRemediaPageState extends State<CriaRemediaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _doseController = TextEditingController();
  final _horarioController = TextEditingController();
  final _intervaloController = TextEditingController();
  
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _isLoading = false;

  static const String _listaHomeKey = 'lista_home_inicial';

  Box<ListaMedicamentoModel> get _listasBox =>
      Hive.box<ListaMedicamentoModel>('minhas_listas');

  @override
  void dispose() {
    _nomeController.dispose();
    _doseController.dispose();
    _horarioController.dispose();
    _intervaloController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(bool isInicio) async {
    final agora = DateTime.now();
    final dataAtual = isInicio ? _dataInicio : _dataFim;
    
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: dataAtual ?? agora,
      firstDate: isInicio ? agora : (_dataInicio ?? agora),
      lastDate: DateTime(agora.year + 5),
    );

    if (dataSelecionada != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = dataSelecionada;
          // Se a data de fim for anterior à de início, atualiza
          if (_dataFim != null && _dataFim!.isBefore(_dataInicio!)) {
            _dataFim = _dataInicio;
          }
        } else {
          _dataFim = dataSelecionada;
        }
      });
    }
  }

  Future<void> _selecionarHorario() async {
    final horarioAtual = _horarioController.text.isNotEmpty
        ? _parseHorario(_horarioController.text)
        : TimeOfDay.now();

    final horarioSelecionado = await showTimePicker(
      context: context,
      initialTime: horarioAtual,
    );

    if (horarioSelecionado != null) {
      setState(() {
        _horarioController.text =
            '${horarioSelecionado.hour.toString().padLeft(2, '0')}:${horarioSelecionado.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  TimeOfDay _parseHorario(String horario) {
    final partes = horario.split(':');
    if (partes.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(partes[0]) ?? 0,
        minute: int.tryParse(partes[1]) ?? 0,
      );
    }
    return TimeOfDay.now();
  }

  String _formatarData(DateTime date) {
    final dia = date.day.toString().padLeft(2, '0');
    final mes = date.month.toString().padLeft(2, '0');
    final ano = date.year.toString();
    return '$dia/$mes/$ano';
  }

  Future<void> _salvarRemedio() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data de início!')),
      );
      return;
    }
    if (_dataFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data de fim!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final novoRemedio = MedicamentoModel(
        nome: _nomeController.text.trim(),
        dose: _doseController.text.trim(),
        horario: _horarioController.text,
        dataInicio: _dataInicio!,
        dataFim: _dataFim!,
        intervaloHoras: int.parse(_intervaloController.text),
      );

      var lista = _listasBox.get(_listaHomeKey);

      if (lista == null) {
        // Se não existir lista, cria uma nova
        lista = ListaMedicamentoModel(
          titulo: 'Minha Lista de Medicamentos',
          medicamentos: [novoRemedio],
        );
        await _listasBox.put(_listaHomeKey, lista);
      } else {
        // Se existir, adiciona à lista
        lista.medicamentos.add(novoRemedio);
        await lista.save();
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${novoRemedio.nome} adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar medicamento: $e'),
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
        title: const Text('Adicionar Medicamento'),
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

              // Dose
              TextFormField(
                controller: _doseController,
                decoration: InputDecoration(
                  labelText: 'Dose (ex: 500mg, 1 comprimido)',
                  prefixIcon: const Icon(Icons.info),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a dose';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Horário
              TextFormField(
                controller: _horarioController,
                decoration: InputDecoration(
                  labelText: 'Horário (HH:MM)',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                readOnly: true,
                onTap: _selecionarHorario,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione o horário';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Intervalo de horas
              TextFormField(
                controller: _intervaloController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Intervalo entre doses (em horas)',
                  prefixIcon: const Icon(Icons.schedule),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o intervalo';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Insira um número válido';
                  }
                  if (int.parse(value) <= 0) {
                    return 'O intervalo deve ser maior que 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Datas do Tratamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Data de Início
              InkWell(
                onTap: () => _selecionarData(true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data de Início',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _dataInicio == null
                                ? 'Selecionar data'
                                : _formatarData(_dataInicio!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data de Fim
              InkWell(
                onTap: () => _selecionarData(false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data de Fim',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _dataFim == null
                                ? 'Selecionar data'
                                : _formatarData(_dataFim!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                      onPressed: _isLoading ? null : _salvarRemedio,
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Adicionar',
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
