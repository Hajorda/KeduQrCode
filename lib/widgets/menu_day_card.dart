import 'package:flutter/material.dart';
import 'package:tedu_qrcode/models/daily_menu.dart';
import 'package:tedu_qrcode/models/menu_item.dart';

/// Displays one day's menu inside an elevated Material 3 card.
class MenuDayCard extends StatelessWidget {
  final DailyMenu menu;

  const MenuDayCard({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: menu.isToday ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: menu.isToday
            ? BorderSide(color: colors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date header ─────────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  menu.isToday
                      ? Icons.today_rounded
                      : Icons.calendar_today_outlined,
                  size: 18,
                  color: menu.isToday ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    menu.formattedDate,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: menu.isToday ? colors.primary : null,
                    ),
                  ),
                ),
                if (menu.isToday)
                  Chip(
                    label: const Text('Bugün'),
                    labelStyle: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: colors.primary,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Menu items ───────────────────────────────────────────────────
            if (menu.items.isEmpty)
              Text(
                'Bu gün için menü bilgisi yok.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            else
              ...menu.items.map((item) => _MenuRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final MenuItem item;
  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _categoryColor(item.category, colors).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.category,
              style: textTheme.labelSmall?.copyWith(
                color: _categoryColor(item.category, colors),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Dish name
          Expanded(
            child: Text(
              item.name,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category, ColorScheme colors) {
    switch (category) {
      case 'Çorba':
        return Colors.orange;
      case 'Ana Yemek':
        return colors.primary;
      case 'Garnitür':
        return Colors.green;
      case 'Tatlı':
        return Colors.pink;
      case 'Meyve':
        return Colors.deepOrange;
      case 'Salata':
        return Colors.teal;
      case 'Ekmek':
        return Colors.brown;
      default:
        return colors.secondary;
    }
  }
}
