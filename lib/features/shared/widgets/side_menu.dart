import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shop_admin/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_shop_admin/features/shared/shared.dart';
import 'package:flutter_shop_admin/features/shared/infrastructure/demo/demo_store.dart';


class SideMenu extends ConsumerStatefulWidget {

  final GlobalKey<ScaffoldState> scaffoldKey;

  const SideMenu({
    super.key, 
    required this.scaffoldKey
  });

  @override
  SideMenuState createState() => SideMenuState();
}


class SideMenuState extends ConsumerState<SideMenu> {

  int navDrawerIndex = 0;

  @override
  Widget build(BuildContext context) {

    final hasNotch = MediaQuery.of(context).viewPadding.top > 35;
    final textStyles = Theme.of(context).textTheme;
    final user = ref.watch(authProvider).user;
    

    // El ancho por defecto del menú (304 px) tapa casi toda la app en pantallas
    // estrechas; se limita al 80 % para que siempre se vea parte del contenido.
    final theme = Theme.of(context);
    final drawerWidth = math.min(304.0, MediaQuery.of(context).size.width * 0.8);

    return Theme(
      data: theme.copyWith(drawerTheme: theme.drawerTheme.copyWith(width: drawerWidth)),
      child: NavigationDrawer(
      elevation: 1,
      selectedIndex: navDrawerIndex,
      onDestinationSelected: (value) {

        setState(() {
          navDrawerIndex = value;
        });

        // final menuItem = appMenuItems[value];
        // context.push( menuItem.link );
        widget.scaffoldKey.currentState?.closeDrawer();

      },
      children: [

        Padding(
          padding: EdgeInsets.fromLTRB(20, hasNotch ? 0 : 20, 16, 0),
          child: Text('Saludos', style: textStyles.titleMedium ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
          child: Text(user?.fullName ?? '', style: textStyles.titleSmall ),
        ),

        const NavigationDrawerDestination(
            icon: Icon( Icons.home_outlined ), 
            label: Text( 'Productos' ),
        ),


        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
          child: Text('Otras opciones'),
        ),

        // Demo web: borra los cambios guardados en el navegador y vuelve al login.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: OutlinedButton.icon(
            onPressed: () async {
              await DemoStore.instance.reset();
              ref.read(authProvider.notifier).logout('Datos de la demo restablecidos');
            },
            icon: const Icon( Icons.restart_alt ),
            label: const Text('Restablecer datos de la demo'),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            text: 'Cerrar sesión'
          ),
        ),
      ]
    ),
    );
  }
}
