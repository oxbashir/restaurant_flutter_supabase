import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: restaurantAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (restaurant) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.name,
                                style:
                                    Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                restaurant.tagline,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => context.push('/orders'),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surface,
                          ),
                          icon: const Icon(Icons.receipt_long_rounded),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.1, end: 0),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: SoftCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.mintSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.mint,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.isOpen
                                      ? 'Open now'
                                      : 'Closed',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: restaurant.isOpen
                                            ? AppColors.success
                                            : AppColors.danger,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${restaurant.address}, ${restaurant.city}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08, end: 0),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: SectionHeader(
                      title: 'How would you like to order?',
                      subtitle: 'Choose delivery or pickup to continue',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList.list(
                    children: [
                      _OrderTypeCard(
                        title: 'Delivery',
                        subtitle:
                            'We bring it to your door · from ${AppConstants.defaultDeliveryFeeCents / 100} €',
                        icon: Icons.delivery_dining_rounded,
                        gradient: AppColors.coralGradient,
                        accent: AppColors.coral,
                        onTap: () {
                          ref
                              .read(orderSessionProvider.notifier)
                              .selectOrderType(OrderType.delivery);
                          context.push('/address');
                        },
                      )
                          .animate()
                          .fadeIn(delay: 180.ms)
                          .slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 14),
                      _OrderTypeCard(
                        title: 'Pickup',
                        subtitle:
                            'Ready in ~${restaurant.prepTimeMinutes} min at the restaurant',
                        icon: Icons.shopping_bag_rounded,
                        gradient: AppColors.mintGradient,
                        accent: AppColors.mint,
                        onTap: () {
                          ref
                              .read(orderSessionProvider.notifier)
                              .selectOrderType(OrderType.pickup);
                          context.push('/menu');
                        },
                      )
                          .animate()
                          .fadeIn(delay: 280.ms)
                          .slideX(begin: 0.05, end: 0),
                      const SizedBox(height: 24),
                      SoftCard(
                        color: AppColors.surface.withValues(alpha: 0.7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s favourites',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Paella, bravas, crema catalana — fresh Mediterranean plates.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                _Pill(label: 'Free delivery over 25 €'),
                                _Pill(label: 'Card · Apple Pay · Google Pay'),
                                _Pill(label: 'IVA included'),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 360.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTypeCard extends StatelessWidget {
  const _OrderTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
      ),
    );
  }
}
