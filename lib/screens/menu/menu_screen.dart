import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(orderSessionProvider);
    final cart = ref.watch(cartProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(menuItemsProvider);

    if (!session.hasOrderType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
    }

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
                      onPressed: () {
                        if (session.orderType == OrderType.delivery) {
                          context.go('/address');
                        } else {
                          context.go('/');
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            session.orderType == OrderType.delivery
                                ? 'Delivery · ${session.address?.city ?? ''}'
                                : 'Pickup at restaurant',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (session.eta != null)
                      EtaBadge(minutes: session.eta!.totalMinutes),
                  ],
                ),
              ),
              if (session.orderType == OrderType.delivery &&
                  session.address != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SoftCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.coral, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.address!.formatted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/address'),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                loading: () => const SizedBox(height: 44),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) {
                  final selected = _selectedCategoryId;
                  return SizedBox(
                    height: 46,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final cat = isAll ? null : categories[index - 1];
                        final isSelected = isAll
                            ? selected == null
                            : selected == cat!.id;
                        return ChoiceChip(
                          label: Text(isAll ? 'All' : cat!.nameEs),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryId = isAll ? null : cat!.id;
                            });
                          },
                          selectedColor:
                              AppColors.coral.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.coralDeep
                                : AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: itemsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (items) {
                    final filtered = _selectedCategoryId == null
                        ? items
                        : items
                            .where((i) => i.categoryId == _selectedCategoryId)
                            .toList();
                    final featured =
                        filtered.where((i) => i.isFeatured).toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        if (featured.isNotEmpty &&
                            _selectedCategoryId == null) ...[
                          SectionHeader(
                            title: 'Featured',
                            subtitle: 'Chef picks today',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 210,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: featured.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final item = featured[index];
                                return _FeaturedCard(
                                  item: item,
                                  onTap: () =>
                                      context.push('/item/${item.id}'),
                                )
                                    .animate()
                                    .fadeIn(delay: (80 * index).ms)
                                    .slideX(begin: 0.05, end: 0);
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                        SectionHeader(
                          title: 'All dishes',
                          subtitle: '${filtered.length} items',
                        ),
                        const SizedBox(height: 12),
                        ...filtered.asMap().entries.map((entry) {
                          final item = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MenuItemTile(
                              item: item,
                              onTap: () => context.push('/item/${item.id}'),
                              onAdd: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addItem(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} added'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(milliseconds: 900),
                                  ),
                                );
                              },
                            ).animate().fadeIn(delay: (40 * entry.key).ms),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              icon: Badge(
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_bag_rounded),
              ),
              label: const Text('View cart'),
            ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.onTap});

  final MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: SoftCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkFoodImage(url: item.imageUrl, height: 110, borderRadius: 0),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  PriceTag(cents: item.priceCents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.item,
    required this.onTap,
    required this.onAdd,
  });

  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkFoodImage(
            url: item.imageUrl,
            height: 92,
            width: 92,
            borderRadius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    PriceTag(cents: item.priceCents),
                    const Spacer(),
                    IconButton.filled(
                      onPressed: onAdd,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(40, 40),
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
