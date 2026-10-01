import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_shop_admin/features/auth/presentation/providers/providers.dart';
import 'package:flutter_shop_admin/features/shared/shared.dart';
import 'package:flutter_shop_admin/features/shared/infrastructure/demo/demo_store.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: GeometricalBackground( 
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox( height: 80 ),
                // Icon Banner
                const Icon( 
                  Icons.production_quantity_limits_rounded, 
                  color: Colors.white,
                  size: 100,
                ),
                const SizedBox( height: 80 ),
    
                Container(
                  // Altura mínima: en pantallas bajas (p. ej. el marco de móvil de la demo
                  // web) el formulario no cabía y quedaba cortado; así se puede hacer scroll.
                  height: math.max( size.height - 260, 600 ), // 80 los dos sizebox y 100 el ícono
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                  ),
                  child: const _LoginForm(),
                )
              ],
            ),
          )
        )
      ),
    );
  }
}

class _LoginForm extends ConsumerWidget {

  const _LoginForm();

  void showSnackbar( BuildContext context, String message ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }


  // Cierra el teclado y la sesión de autocompletado de iOS antes de cambiar de pantalla;
  // si no, el campo de contraseña puede quedarse enganchado y bloquear el teclado del siguiente login
  void submit( WidgetRef ref ) {
    FocusManager.instance.primaryFocus?.unfocus();
    TextInput.finishAutofillContext();
    ref.read(loginFormProvider.notifier).onFormSubmit();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final loginForm = ref.watch(loginFormProvider);

    ref.listen(authProvider, (previous, next) {
      if ( next.errorMessage.isEmpty ) return;
      showSnackbar( context, next.errorMessage );
    });


    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: AutofillGroup(
      child: Column(
        children: [
          const SizedBox( height: 50 ),
          Text('Login', style: textStyles.titleLarge ),
          const SizedBox( height: 90 ),

          CustomTextFormField(
            label: 'Correo',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [ AutofillHints.email ],
            onChanged: ref.read(loginFormProvider.notifier).onEmailChange,
            errorMessage: loginForm.isFormPosted ?
               loginForm.email.errorMessage 
               : null,
          ),
          const SizedBox( height: 30 ),

          CustomTextFormField(
            label: 'Contraseña',
            obscureText: true,
            autofillHints: const [ AutofillHints.password ],
            onChanged: ref.read(loginFormProvider.notifier).onPasswordChanged,
            onFieldSubmitted: ( _ ) => submit(ref),
            errorMessage: loginForm.isFormPosted ?
               loginForm.password.errorMessage 
               : null,
          ),
    
          const SizedBox( height: 30 ),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Ingresar',
              buttonColor: Colors.black,
              onPressed: loginForm.isPosting
                ? null 
                : () => submit(ref)
            )
          ),

          const SizedBox( height: 10 ),

          // Demo web: acceso directo con el usuario de prueba.
          TextButton.icon(
            onPressed: loginForm.isPosting
              ? null
              : () {
                FocusManager.instance.primaryFocus?.unfocus();
                ref.read(authProvider.notifier).loginUser(DemoStore.demoEmail, DemoStore.demoPassword);
              },
            icon: const Icon( Icons.play_circle_outline ),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Entrar con el usuario de demo', textAlign: TextAlign.center),
                Text(
                  '${ DemoStore.demoEmail } · ${ DemoStore.demoPassword }',
                  style: textStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Spacer( flex: 2 ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta?'),
              TextButton(
                onPressed: ()=> context.push('/register'), 
                child: const Text('Crea una aquí')
              )
            ],
          ),

          const Spacer( flex: 1),
        ],
      ),
      ),
    );
  }
}