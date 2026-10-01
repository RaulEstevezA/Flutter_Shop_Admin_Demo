import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shop_admin/config/config.dart';


void main() {
  runApp(
    const ProviderScope(child: MainApp())
  );
}


class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref ) {

    final appRouter = ref.watch( goRouterProvider );

    return MaterialApp.router(
      routerConfig: appRouter,
      theme: AppTheme().getTheme(),
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _DragScrollBehavior(),
    );
  }
}

// En web, Flutter solo permite arrastrar listas con el dedo; esto habilita
// también el ratón y el trackpad (catálogo y galería de fotos en escritorio).
class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
