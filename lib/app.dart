import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/constants.dart';
import 'config/env.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SaborApp extends ConsumerWidget {
  const SaborApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!Env.useDemoMode) return content;
        return Banner(
          message: 'DEMO',
          location: BannerLocation.topEnd,
          color: AppColors.citrus,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
          child: content,
        );
      },
    );
  }
}
