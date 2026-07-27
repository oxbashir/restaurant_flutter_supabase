import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totals = ref.watch(cartTotalsProvider);
    final session = ref.watch(orderSessionProvider);
    final restaurant =
        ref.watch(restaurantProvider).valueOrNull ?? DemoData.restaurant;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Your cart',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (!cart.isEmpty)
                      TextButton(
                        onPressed: () =>
                            ref.read(cartProvider.notifier).clear(),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: cart.isEmpty
                    ? EmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Cart is empty',
                        message: 'Browse the menu and add something delicious.',
                        action: PrimaryButton(
                          label: 'Back to menu',
                          expand: false,
                          onPressed: () => context.go('/menu'),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          ...cart.lines.map((line) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SoftCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    NetworkFoodImage(
                                      url: line.item.imageUrl,
                                      width: 72,
                                      height: 72,
                                      borderRadius: 14,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            line.item.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          PriceTag(cents: line.item.priceCents),
                                          if (line.notes.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              line.notes,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          QtyStepper(
                                            value: line.quantity,
                                            min: 0,
                                            onChanged: (v) => ref
                                                .read(cartProvider.notifier)
                                                .setQuantity(line.item.id, v),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PriceTag(cents: line.lineTotalCents),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          SoftCard(
                            child: Column(
                              children: [
                                _RowLine(
                                  label: 'Subtotal',
                                  cents: totals.subtotal,
                                ),
                                const SizedBox(height: 8),
                                _RowLine(
                                  label: session.orderType == OrderType.pickup
                                      ? 'Pickup'
                                      : 'Delivery',
                                  cents: totals.deliveryFee,
                                  trailing: totals.deliveryFee == 0 &&
                                          session.orderType ==
                                              OrderType.delivery
                                      ? 'Free'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                _RowLine(
                                  label: 'IVA included (10%)',
                                  cents: totals.tax,
                                  muted: true,
                                ),
                                const Divider(height: 24),
                                _RowLine(
                                  label: 'Total',
                                  cents: totals.total,
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                          if (totals.subtotal < restaurant.minOrderCents) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Minimum order is ${Money.formatCents(restaurant.minOrderCents)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.danger),
                            ),
                          ] else if (session.orderType == OrderType.delivery &&
                              totals.subtotal <
                                  restaurant.freeDeliveryOverCents) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Add ${Money.formatCents(restaurant.freeDeliveryOverCents - totals.subtotal)} more for free delivery',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
              ),
              if (!cart.isEmpty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: PrimaryButton(
                      label: 'Checkout · ${Money.formatCents(totals.total)}',
                      icon: Icons.lock_rounded,
                      onPressed: totals.subtotal < restaurant.minOrderCents
                          ? null
                          : () => context.push('/checkout'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  const _RowLine({
    required this.label,
    required this.cents,
    this.trailing,
    this.bold = false,
    this.muted = false,
  });

  final String label;
  final int cents;
  final String? trailing;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: muted ? AppColors.inkSoft : AppColors.ink,
            );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          trailing ?? Money.formatCents(cents),
          style: style,
        ),
      ],
    );
  }
}
