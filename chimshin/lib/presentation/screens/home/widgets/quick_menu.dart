import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class QuickMenu extends StatelessWidget {
  final VoidCallback onSermonListTap;
  final VoidCallback onNoticeTap;

  const QuickMenu({
    super.key,
    required this.onSermonListTap,
    required this.onNoticeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 기능',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickMenuItem(
                icon: Icons.menu_book,
                label: '설교 노트',
                color: AppColors.primary,
                onTap: onSermonListTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickMenuItem(
                icon: Icons.campaign_rounded,
                label: '침신/교회 소식',
                color: const Color(0xFF1565C0),
                onTap: onNoticeTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
