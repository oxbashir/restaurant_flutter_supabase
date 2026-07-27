import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/demo_data.dart';
import '../../services/order_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _notesCtrl;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = ref.read(orderSessionProvider);
    _nameCtrl = TextEditingController(text: session.guestName);
    _emailCtrl = TextEditingController(text: session.guestEmail);
    _phoneCtrl = TextEditingController(text: session.guestPhone);
    _notesCtrl = TextEditingController(text: session.specialInstructions);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    final session = ref.read(orderSessionProvider);
    final cart = ref.read(cartProvider);
    final totals = ref.read(cartTotalsProvider);

    if (session.orderType == null || cart.isEmpty) {
      setState(() => _error = 'Your session expired. Start again from home.');
      return;
    }

    if (session.orderType == OrderType.delivery &&
        (session.address == null || session.eta == null)) {
      setState(() => _error = 'Delivery address is required.');
      return;
    }

    setState(() {
      _paying = true;
      _error = null;
    });

    ref.read(orderSessionProvider.notifier).updateGuest(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          instructions: _notesCtrl.text.trim(),
        );

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final payment = ref.read(paymentServiceProvider);

      final order = await orderRepo.createOrder(
        CreateOrderRequest(
          orderType: session.orderType!,
          items: cart.lines,
          subtotalCents: totals.subtotal,
          deliveryFeeCents: totals.deliveryFee,
          taxCents: totals.tax,
          totalCents: totals.total,
          guestName: _nameCtrl.text.trim(),
          guestEmail: _emailCtrl.text.trim(),
          guestPhone: _phoneCtrl.text.trim(),
          address: session.address,
          eta: session.eta,
          specialInstructions: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        ),
      );

      final paymentIntentId = await payment.pay(
        orderId: order.id,
        amountCents: totals.total,
        customerEmail: _emailCtrl.text.trim(),
        customerName: _nameCtrl.text.trim(),
      );

      final paid = await orderRepo.markPaid(
        orderId: order.id,
        paymentIntentId: paymentIntentId,
      );

      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      context.go('/order/${paid.id}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(orderSessionProvider);
    final totals = ref.watch(cartTotalsProvider);

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
                        'Checkout',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.orderType == OrderType.delivery
                                    ? 'Delivery details'
                                    : 'Pickup details',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              if (session.orderType == OrderType.delivery &&
                                  session.address != null) ...[
                                Text(session.address!.formatted),
                                if (session.eta != null) ...[
                                  const SizedBox(height: 8),
                                  EtaBadge(
                                    minutes: session.eta!.totalMinutes,
                                    label:
                                        'ETA ~${session.eta!.totalMinutes} min · ${session.eta!.distanceKm} km',
                                  ),
                                ],
                              ] else ...[
                                Text(
                                  'Collect at Calle de Serrano 45, Madrid',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (session.eta != null) ...[
                                  const SizedBox(height: 8),
                                  EtaBadge(
                                    minutes: session.eta!.totalMinutes,
                                    label:
                                        'Ready in ~${session.eta!.totalMinutes} min',
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Contact',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 2)
                                  ? 'Required'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@email.com',
                          ),
                          validator: (v) {
                            if (v == null || !v.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            hintText: '+34 600 000 000',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 8)
                                  ? 'Enter a valid phone'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Order notes (optional)',
                          ),
                        ),
                        const SizedBox(height: 18),
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment · Spain',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                Env.useDemoMode || !Env.isStripeConfigured
                                    ? 'Demo mode: payment is simulated. Connect Stripe keys for live EUR payments.'
                                    : 'Secure Stripe checkout in EUR. Cards, Apple Pay & Google Pay supported in Spain.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _PayChip(label: 'Visa'),
                                  _PayChip(label: 'Mastercard'),
                                  _PayChip(label: 'Apple Pay'),
                                  _PayChip(label: 'Google Pay'),
                                  _PayChip(label: 'EUR'),
                                ],
                              ),
                              const Divider(height: 28),
                              Row(
                                children: [
                                  Text(
                                    'Total due',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  PriceTag(cents: totals.total),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.danger),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: PrimaryButton(
                    label: Env.useDemoMode || !Env.isStripeConfigured
                        ? 'Pay ${Money.formatCents(totals.total)} (demo)'
                        : 'Pay ${Money.formatCents(totals.total)}',
                    icon: Icons.payment_rounded,
                    isLoading: _paying,
                    onPressed: _pay,
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

class _PayChip extends StatelessWidget {
  const _PayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
      ),
    );
  }
}
