import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/env.dart';
import '../models/models.dart';

class PaymentService {
  PaymentService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  final _uuid = const Uuid();

  Future<void> init() async {
    if (!Env.isStripeConfigured) return;
    Stripe.publishableKey = Env.stripePublishableKey;
    Stripe.merchantIdentifier = 'merchant.com.sabor.restaurant';
    await Stripe.instance.applySettings();
  }

  Future<PaymentIntentResult> createPaymentIntent({
    required String orderId,
    required int amountCents,
    required String customerEmail,
    required String customerName,
  }) async {
    final client = _client;
    if (Env.useDemoMode || !Env.isStripeConfigured || client == null) {
      return PaymentIntentResult(
        clientSecret: 'demo_secret_${_uuid.v4()}',
        paymentIntentId: 'pi_demo_${_uuid.v4()}',
      );
    }

    final response = await client.functions.invoke(
      'create-payment-intent',
      body: {
        'orderId': orderId,
        'amount': amountCents,
        'currency': Env.currency,
        'email': customerEmail,
        'name': customerName,
        'country': Env.merchantCountryCode,
      },
    );

    if (response.status != 200) {
      throw Exception('Unable to start payment: ${response.data}');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    return PaymentIntentResult(
      clientSecret: data['clientSecret'] as String,
      paymentIntentId: data['paymentIntentId'] as String,
      ephemeralKey: data['ephemeralKey'] as String?,
      customerId: data['customerId'] as String?,
    );
  }

  /// Presents Stripe Payment Sheet configured for Spain (EUR, ES).
  /// In demo mode, simulates a successful card payment.
  Future<String> pay({
    required String orderId,
    required int amountCents,
    required String customerEmail,
    required String customerName,
  }) async {
    final intent = await createPaymentIntent(
      orderId: orderId,
      amountCents: amountCents,
      customerEmail: customerEmail,
      customerName: customerName,
    );

    if (Env.useDemoMode || !Env.isStripeConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return intent.paymentIntentId;
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: intent.clientSecret,
        merchantDisplayName: Env.merchantDisplayName,
        customerId: intent.customerId,
        customerEphemeralKeySecret: intent.ephemeralKey,
        style: ThemeMode.light,
        billingDetails: BillingDetails(
          name: customerName,
          email: customerEmail,
          address: const Address(
            city: '',
            country: 'ES',
            line1: '',
            line2: '',
            postalCode: '',
            state: '',
          ),
        ),
        returnURL: Env.stripeReturnUrl,
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'ES',
          currencyCode: 'EUR',
          testEnv: kDebugMode,
        ),
        applePay: const PaymentSheetApplePay(
          merchantCountryCode: 'ES',
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return intent.paymentIntentId;
  }
}
