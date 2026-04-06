import 'package:conexao_saude/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MedicamentoItemCard extends StatelessWidget {
  final String nome;
  final String quantidade;
  final String hora;
  final String data;
  final String? imageUrl;

  const MedicamentoItemCard({
    super.key,
    required this.nome,
    required this.quantidade,
    required this.hora,
    required this.data,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
                    _InfoChip(icon: Icons.access_time, label: hora),
                    _InfoChip(icon: Icons.calendar_month, label: data),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
