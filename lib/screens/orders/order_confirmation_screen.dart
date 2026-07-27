import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  RestaurantOrder? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final order =
          await ref.read(orderRepositoryProvider).fetchOrder(widget.orderId);
      setState(() {
        _order = order;
        _loading = false;
        if (order == null) _error = 'Order not found';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? EmptyState(
                      icon: Icons.error_outline,
                      title: 'Something went wrong',
                      message: _error!,
                      action: PrimaryButton(
                        label: 'Home',
                        expand: false,
                        onPressed: () => context.go('/'),
                      ),
                    )
                  : _SuccessBody(order: _order!),
        ),
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.order});

  final RestaurantOrder order;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final ready = order.estimatedReadyAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppColors.mintGradient,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  )
                      .animate()
                      .scale(duration: 450.ms, curve: Curves.easeOutBack)
                      .fadeIn(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Order confirmed!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(delay: 120.ms),
                const SizedBox(height: 8),
                Text(
                  order.orderNumber,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.coralDeep,
                      ),
                ),
                const SizedBox(height: 20),
                SoftCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.receipt_long_rounded,
                        label: 'Status',
                        value: order.status.label,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: order.orderType == OrderType.delivery
                            ? Icons.delivery_dining_rounded
                            : Icons.shopping_bag_rounded,
                        label: order.orderType.label,
                        value: ready == null
                            ? 'Preparing'
                            : 'Ready around ${timeFmt.format(ready)}',
                      ),
                      if (order.orderType == OrderType.delivery &&
                          order.deliveryStreet != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Address',
                          value:
                              '${order.deliveryStreet}, ${order.deliveryPostalCode} ${order.deliveryCity}',
                        ),
                      ],
                      if (order.distanceKm != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.route_rounded,
                          label: 'Distance',
                          value: '${order.distanceKm} km',
                        ),
                      ],
                      const Divider(height: 28),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                '${item.quantity}×',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item.name)),
                              Text(
                                Money.formatCents(
                                  item.unitPriceCents * item.quantity,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Text(
                            'Total paid',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          PriceTag(cents: order.totalCents),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
          PrimaryButton(
            label: 'Order again',
            onPressed: () => context.go('/'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.go('/orders'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('View my orders'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.coral, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
