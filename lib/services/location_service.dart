import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/models.dart';
import 'demo_data.dart';

class LocationService {
  Future<bool> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> currentPosition() async {
    final ok = await ensurePermission();
    if (!ok) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<DeliveryAddress?> addressFromCurrentLocation() async {
    final position = await currentPosition();
    if (position == null) return null;

    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isEmpty) {
        return DeliveryAddress(
          street: 'Current location',
          city: 'Madrid',
          postalCode: '28001',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
      final p = places.first;
      final street = [
        if ((p.thoroughfare ?? '').isNotEmpty) p.thoroughfare,
        if ((p.subThoroughfare ?? '').isNotEmpty) p.subThoroughfare,
      ].whereType<String>().join(' ');

      return DeliveryAddress(
        street: street.isEmpty ? (p.name ?? 'Address') : street,
        city: p.locality ?? p.subAdministrativeArea ?? 'Madrid',
        postalCode: p.postalCode ?? '',
        country: p.isoCountryCode ?? 'ES',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return DeliveryAddress(
        street: 'Current location',
        city: 'Madrid',
        postalCode: '28001',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }

  Future<DeliveryAddress> geocodeAddress({
    required String street,
    required String city,
    required String postalCode,
    String country = 'Spain',
    String? notes,
  }) async {
    try {
      final query = '$street, $postalCode $city, $country';
      final results = await locationFromAddress(query);
      if (results.isNotEmpty) {
        return DeliveryAddress(
          street: street,
          city: city,
          postalCode: postalCode,
          country: 'ES',
          latitude: results.first.latitude,
          longitude: results.first.longitude,
          notes: notes,
        );
      }
    } catch (_) {
      // Fall through to Madrid-area approximation for demo / offline.
    }

    // Deterministic offset from restaurant using postal code hash so ETA varies.
    final hash = postalCode.hashCode.abs();
    final latOffset = ((hash % 100) - 50) / 1000.0;
    final lonOffset = (((hash ~/ 100) % 100) - 50) / 1000.0;
    final restaurant = DemoData.restaurant;

    return DeliveryAddress(
      street: street,
      city: city,
      postalCode: postalCode,
      country: 'ES',
      latitude: restaurant.latitude + latOffset,
      longitude: restaurant.longitude + lonOffset,
      notes: notes,
    );
  }
}
