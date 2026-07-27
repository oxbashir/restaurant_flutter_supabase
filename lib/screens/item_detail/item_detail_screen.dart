import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final MenuItem item;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  int _qty = 1;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: AppColors.cream,
                    leading: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: NetworkFoodImage(
                        url: item.imageUrl,
                        height: 320,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          PriceTag(
                            cents: item.priceCents,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: AppColors.coralDeep),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (item.calories != null)
                                _InfoChip(
                                  icon: Icons.local_fire_department_outlined,
                                  label: '${item.calories} kcal',
                                ),
                              if (item.prepMinutes != null)
                                _InfoChip(
                                  icon: Icons.timer_outlined,
                                  label: '${item.prepMinutes} min',
                                ),
                              ...item.tags.map(
                                (t) => _InfoChip(
                                  icon: Icons.sell_outlined,
                                  label: t,
                                ),
                              ),
                            ],
                          ),
                          if (item.allergens.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              'Allergens',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.allergens.join(', '),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'Special notes',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'No onion, extra sauce…',
                            ),
                          ),
                          const SizedBox(height: 20),
                          QtyStepper(
                            value: _qty,
                            onChanged: (v) => setState(() => _qty = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: PrimaryButton(
                  label:
                      'Add $_qty · ${((item.priceCents * _qty) / 100).toStringAsFixed(2).replaceAll('.', ',')} €',
                  icon: Icons.add_shopping_cart_rounded,
                  onPressed: () {
                    ref.read(cartProvider.notifier).addItem(
                          item,
                          quantity: _qty,
                          notes: _notesCtrl.text.trim(),
                        );
                    context.pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.inkSoft),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
