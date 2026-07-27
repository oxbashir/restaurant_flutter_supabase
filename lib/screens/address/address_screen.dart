import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Madrid');
  final _postalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final address =
          await ref.read(locationServiceProvider).addressFromCurrentLocation();
      if (address == null) {
        setState(() {
          _error =
              'Location permission denied or unavailable. Enter your address manually.';
        });
        return;
      }
      _streetCtrl.text = address.street;
      _cityCtrl.text = address.city;
      _postalCtrl.text = address.postalCode;
      await ref.read(orderSessionProvider.notifier).setDeliveryAddress(address);
      if (!mounted) return;
      context.go('/menu');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final address = await ref.read(locationServiceProvider).geocodeAddress(
            street: _streetCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            postalCode: _postalCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      await ref.read(orderSessionProvider.notifier).setDeliveryAddress(address);

      final eta = ref.read(orderSessionProvider).eta;
      if (eta != null && !eta.withinRadius) {
        setState(() {
          _error =
              'Sorry — this address is outside our ${ref.read(restaurantProvider).valueOrNull?.deliveryRadiusKm ?? 12} km delivery radius (${eta.distanceKm} km away).';
        });
        return;
      }

      if (!mounted) return;
      context.go('/menu');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(orderSessionProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Delivery address',
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
                                'Where should we deliver?',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'We estimate arrival from the distance to our Madrid kitchen.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _loading ? null : _useCurrentLocation,
                                icon: const Icon(Icons.my_location_rounded),
                                label: const Text('Use current location'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _streetCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Street & number',
                            hintText: 'Calle de Alcalá 100',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 4)
                                  ? 'Enter a valid street'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _cityCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _postalCtrl,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'CP',
                                  hintText: '28001',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().length < 4) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Delivery notes (optional)',
                            hintText: 'Floor, door code, landmark…',
                          ),
                        ),
                        if (session.eta != null) ...[
                          const SizedBox(height: 18),
                          SoftCard(
                            color: AppColors.mintSoft,
                            child: Row(
                              children: [
                                const Icon(Icons.route_rounded,
                                    color: AppColors.mint),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Estimated arrival ~${session.eta!.totalMinutes} min',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        '${session.eta!.distanceKm} km · prep ${session.eta!.prepMinutes} min · travel ${session.eta!.travelMinutes} min',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.danger),
                          ),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Continue to menu',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: _loading,
                          onPressed: _continue,
                        ),
                      ],
                    ),
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
