import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../widgets/rumbo_button.dart';

/// Bottom sheet para recuperar la contraseña.
///
/// Al terminar muestra el estado de éxito "Revisa tu correo".
Future<void> showForgotPasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => const _ForgotPasswordSheet(),
  );
}

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet();

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _done = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.status == AuthStatus.loading;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_reset, color: AppColors.orange, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Recuperar contraseña',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Cerrar',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_done) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.successBg.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.mark_email_read_outlined,
                      color: AppColors.success, size: 36),
                  SizedBox(height: 10),
                  Text(
                    'Revisa tu correo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Te enviamos un enlace para restablecer tu contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'Escribe tu correo universitario y te enviaremos un enlace.',
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) => _send(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Escribe un correo válido';
                  }
                  if (!v
                      .trim()
                      .toLowerCase()
                      .endsWith(AppConstants.emailSuffix)) {
                    return 'Usa tu correo universitario '
                        '(${AppConstants.emailSuffix})';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Correo universitario',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
            RumboButton.primary(
              label: 'Enviar enlace',
              isLoading: isLoading,
              onPressed: _send,
            ),
          ],
        ],
      ),
    );
  }
}
