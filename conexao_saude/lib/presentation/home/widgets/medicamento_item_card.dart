import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MedicamentoItemCard extends StatelessWidget {
  final String nome;
  final String quantidade;
  final String hora;
  final String data;
  final int diasConsumidos;
  final String? imageUrl;
  final String? duracao;
  final String? dataInicio;
  final String? dataFim;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicamentoItemCard({
    super.key,
    required this.nome,
    required this.quantidade,
    required this.hora,
    required this.data,
    required this.diasConsumidos,
    required this.onTap,
    this.imageUrl,
    this.duracao,
    this.dataInicio,
    this.dataFim,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent, 
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Garante que a foto fica sempre alinhada ao topo
            children: [
              _buildImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(icon: Icons.medication_outlined, label: 'Qtd: $quantidade'),
                        Builder(
                          builder: (context) {
                            final String horaSoA = hora.split(':').first;
                            final int? horaInteira = int.tryParse(horaSoA);
                            final int horaSegura = horaInteira ?? 8;
                            final bool isDia = (horaSegura >= 6 && horaSegura < 18); 
                            
                            return _InfoChip(
                              icon: isDia ? Icons.wb_sunny : Icons.nightlight_round,
                              iconColor: isDia ? Colors.orange : Colors.blueGrey,
                              label: hora,
                            );
                          }
                        ),
                        
                        _InfoChip(icon: Icons.calendar_today, label: data), 
                        
                        _InfoChip(icon: Icons.check_circle_outline, label: 'Consumidos: $diasConsumidos'),
                        
                        if (duracao != null && duracao!.trim().isNotEmpty)
                          _InfoChip(icon: Icons.schedule, label: 'Dur.: $duracao'),
                        if (dataInicio != null && dataInicio!.trim().isNotEmpty)
                          _InfoChip(icon: Icons.date_range, label: 'Início: $dataInicio'),
                        if (dataFim != null && dataFim!.trim().isNotEmpty)
                          _InfoChip(icon: Icons.event_available, label: 'Fim: $dataFim'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    if (onEdit != null)
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Deletar'),
                          ],
                        ),
                      ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackImage(),
        ),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.medication_liquid, color: AppColors.primary),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _InfoChip({
    required this.icon, 
    required this.label, 
    this.iconColor, 
  });

  @override
  Widget build(BuildContext context) {
    // =====================================================================
    // A MÁGICA ACONTECE AQUI:
    // O ConstrainedBox impede o balãozinho de crescer além de 55% da tela.
    // O Flexible + TextOverflow.ellipsis coloca os "..." se passar desse limite.
    // =====================================================================
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.55, 
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}