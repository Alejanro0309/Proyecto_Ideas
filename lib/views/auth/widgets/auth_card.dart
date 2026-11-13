import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsService;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_constants.dart';
import '../../../config/router/app_router.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/student_profile.dart';
import '../../widgets/rumbo_button.dart';
import '../../widgets/rumbo_logo.dart';
import '../../student/carnet_gate.dart';
import '../login_screen.dart' show translateAuthError;
import 'error_banner_translated.dart';
import 'password_field.dart';
import 'tipo_cuenta_selector.dart';

/// Tarjeta blanca centrada con el formulario de ingreso o registro.
class AuthCard extends ConsumerStatefulWidget {
  const AuthCard({
    super.key,
    required this.isRegisterMode,
    required this.onToggleMode,
    required this.isLoading,
    required this.errorMessage,
    required this.onForgotPassword,
  });
  final bool isRegisterMode;
  final VoidCallback onToggleMode;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onForgotPassword;

  @override
  ConsumerState<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends ConsumerState<AuthCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _empresaCtrl = TextEditingController();
  final _tipoEmpresaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool _termsAccepted = false;
  String? _formError;

  /// Tipo de cuenta elegido en el registro (solo uno).
  /// Por defecto es Estudiante, como pide el diseño.
  TipoCuenta _tipoCuenta = TipoCuenta.estudiante;

  /// Fecha de nacimiento (solo estudiante), elegida con calendario.
  DateTime? _fechaNacimiento;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _apellidoCtrl.dispose();
    _empresaCtrl.dispose();
    _tipoEmpresaCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.isRegisterMode && !_termsAccepted) {
      setState(() => _formError = 'Acepta los términos para crear tu cuenta.');
      return;
    }
    setState(() => _formError = null);
    HapticFeedback.lightImpact();

    final notifier = ref.read(authControllerProvider.notifier);

    if (widget.isRegisterMode) {
      final esEmpresa = _tipoCuenta == TipoCuenta.empresa;
      await notifier.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        // Empresa: nombre y tipo de empresa. Estudiante: nombre y apellido.
        nombre: esEmpresa ? _empresaCtrl.text.trim() : _nameCtrl.text.trim(),
        apellido: esEmpresa ? null : _apellidoCtrl.text.trim(),
        fechaNacimiento: esEmpresa
            ? null
            : _fechaNacimiento?.toIso8601String().split('T').first,
        tipoCuenta: esEmpresa ? 'empresa' : 'estudiante',
        tipoEmpresa: esEmpresa ? _tipoEmpresaCtrl.text.trim() : null,
        telefono: esEmpresa
            ? _telefonoCtrl.text.replaceAll(RegExp(r'\s+'), ' ').trim()
            : null,
      );
    } else {
      await notifier.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    }

    if (!mounted) return;
    final state = ref.read(authControllerProvider);

    if (state.status == AuthStatus.success) {
      // Redirección por rol: la empresa va a su panel, el admin a revisiones
      // y el estudiante al panel (o al escáner si aún no verifica el carnet).
      final rol = await _rolActual(ref);
      // Cacheado para el `redirect` del router (ver app_router.dart).
      rolCacheado = rol;

      if (!mounted) return;
      switch (rol) {
        case 'empresa':
          context.go(AppRoutes.empresa);
        case 'admin':
          context.go(AppRoutes.revisiones);
        default:
          final puedeEntrar = await CarnetGate.puedeEntrarSinCarnet(ref);
          if (!mounted) return;
          context.go(puedeEntrar ? AppRoutes.panel : AppRoutes.scanner);
      }
    } else if (state.status == AuthStatus.error) {
      SemanticsService.announce(
        translateAuthError(state.errorMessage),
        Directionality.of(context),
      );
      setState(
        () => _formError = translateAuthError(state.errorMessage),
      );
    }
  }

  /// Rol del usuario actual (`estudiante`, `empresa` o `admin`).
  ///
  /// Se lee **directamente del servicio de auth**, no del stream
  /// `currentUserProvider`: ese stream puede emitir `null` justo después del
  /// login (antes de que la sesión esté lista) y hacer que una empresa se
  /// confunda con estudiante y acabe en `/panel`.
  ///
  /// Una cuenta de empresa **siempre** va a `/empresa`: no pasa por la
  /// verificación de carnet ni por ninguna revisión de admin (registro
  /// directo, sin aprobación previa).
  Future<String> _rolActual(WidgetRef ref) async {
    final repo = ref.read(profileRepositoryProvider);
    try {
      final auth = ref.read(authServiceProvider);
      final user = auth.currentUser ??
          (await ref.read(supabaseAuthStateProvider.future)
                  .timeout(const Duration(seconds: 8)))
              ?.session
              ?.user;
      if (user == null) return 'estudiante';

      StudentProfile? profile;
      try {
        profile = await repo.getProfile(user.id).timeout(
              const Duration(seconds: 8),
            );
      } catch (_) {
        // Si la lectura falla (timeout, red), se intenta el fallback.
        profile = null;
      }

      if (profile != null) {
        // coalesce(tipo_cuenta, rol): las filas antiguas pueden tener
        // tipo_cuenta = null y rol = 'empresa'.
        if (profile.esEmpresa) return 'empresa';
        return profile.rol ?? 'estudiante';
      }

      // Fallback: la fila de `perfiles` puede no existir (cuentas nuevas de
      // empresa). Se consulta `empresas_nueva` antes de mandar al estudiante.
      final esEmpresa = await repo.existeEnEmpresasNueva(user.id).timeout(
            const Duration(seconds: 8),
          );
      return esEmpresa ? 'empresa' : 'estudiante';
    } catch (e, st) {
      debugPrint('[auth] _rolActual falló: $e\n$st');
      return 'estudiante';
    }
  }

  Future<void> _signInWithGoogle() async {
    // TODO(backend): el flujo OAuth de Google debe registrar el proveedor en
    // Supabase y validar el dominio @correo.unimet.edu.ve. Si la cuenta de
    // Google no pertenece al dominio, el servidor la rechaza y se muestra el
    // mensaje de "correo no permitido".
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inicio con Google no disponible aún.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // El botón se achica si el ancho es muy estrecho.
                  Flexible(
                    child: TextButton.icon(
                      onPressed: () => context.go(AppRoutes.landing),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text(
                        'Volver al inicio',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.inkMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  const Flexible(child: RumboLogo(pill: true)),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  widget.isRegisterMode
                      ? 'Crea tu cuenta'
                      : 'Ingresa a tu cuenta',
                  key: ValueKey(widget.isRegisterMode),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isRegisterMode
                    ? 'Regístrate con tu correo'
                    : 'Usa tu correo (universitario o de empresa)',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.inkMuted,
                ),
              ),
              if (widget.isRegisterMode) ...[
                const SizedBox(height: 20),
                TipoCuentaSelector(
                  valor: _tipoCuenta,
                  onChanged: (v) => setState(() {
                    _tipoCuenta = v;
                    // Al elegir, se limpia el error si lo hubiera.
                    if (_formError != null) _formError = null;
                  }),
                ),
              ],
              const SizedBox(height: 20),
              if (_formError != null) ...[
                ErrorBannerTranslated(message: _formError!),
                const SizedBox(height: 16),
              ],
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.isRegisterMode) ...[
                      // ─── Empresa ────────────────────────────────────
                      if (_tipoCuenta == TipoCuenta.empresa) ...[
                        TextFormField(
                          controller: _empresaCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: _validateEmpresa,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la empresa',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tipoEmpresaCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: _validateTipoEmpresa,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de empresa',
                            prefixIcon: Icon(Icons.category_outlined),
                            helperText: 'Ej.: Tecnología, Comercio, Servicios…',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _telefonoCtrl,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          validator: _validateTelefono,
                          decoration: const InputDecoration(
                            labelText: 'Número de teléfono',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ],

                      // ─── Estudiante ─────────────────────────────────
                      if (_tipoCuenta == TipoCuenta.estudiante) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                autofillHints: const [AutofillHints.givenName],
                                validator: _validateName,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _apellidoCtrl,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                autofillHints: const [AutofillHints.familyName],
                                validator: _validateApellido,
                                decoration: const InputDecoration(
                                  labelText: 'Apellido',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FechaNacimientoField(
                          fecha: _fechaNacimiento,
                          onChanged: (v) =>
                              setState(() => _fechaNacimiento = v),
                        ),
                      ],
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: const Icon(Icons.email_outlined),
                        helperText: widget.isRegisterMode
                            ? (_tipoCuenta == TipoCuenta.empresa
                                ? 'Usa un correo válido'
                                : 'Debe terminar en ${AppConstants.emailSuffix}')
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordCtrl,
                      label: 'Contraseña',
                      textInputAction: widget.isRegisterMode
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: _validatePassword,
                      onFieldSubmitted:
                          widget.isRegisterMode ? null : (_) => _submit(),
                    ),
                    if (widget.isRegisterMode) ...[
                      const SizedBox(height: 8),
                      _PasswordStrengthBar(controller: _passwordCtrl),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirmCtrl,
                        label: 'Confirmar contraseña',
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: (v) => _validateConfirm(v),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 16),
                      _TermsCheckbox(
                        value: _termsAccepted,
                        onChanged: (v) => setState(() => _termsAccepted = v),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RumboButton.primary(
                label: widget.isRegisterMode ? 'Crear cuenta' : 'Ingresar',
                isLoading: widget.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'o',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.line)),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.isLoading ? null : _signInWithGoogle,
                icon: const _GoogleLogo(),
                label: const Text('Continuar con Google'),
              ),
              const SizedBox(height: 16),
              if (!widget.isRegisterMode)
                Center(
                  child: TextButton(
                    onPressed: widget.onForgotPassword,
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: widget.isRegisterMode
                        ? '¿Ya tienes cuenta? '
                        : '¿No tienes cuenta? ',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.inkMuted,
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: widget.onToggleMode,
                          child: Text(
                            widget.isRegisterMode ? 'Ingresa' : 'Regístrate',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orangeText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Escribe tu nombre';
    if (value.trim().length < 2) return 'Escribe tu nombre';
    return null;
  }

  String? _validateApellido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Escribe tu apellido';
    if (value.trim().length < 2) return 'Escribe tu apellido';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Escribe un correo válido';
    final normalized = value.trim().toLowerCase();
    // Formato general: algo@dominio.punto (cualquier dominio, no solo el
    // universitario: ahora también hay cuentas de empresa).
    final formato = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!formato.hasMatch(normalized)) {
      return 'Escribe un correo válido (nombre@dominio.com)';
    }
    // Solo en registro de estudiante se exige el correo universitario.
    if (widget.isRegisterMode &&
        _tipoCuenta == TipoCuenta.estudiante &&
        !normalized.endsWith(AppConstants.emailSuffix)) {
      return 'Usa tu correo universitario (${AppConstants.emailSuffix})';
    }
    return null;
  }

  String? _validateEmpresa(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escribe el nombre de la empresa';
    }
    if (value.trim().length < 3) return 'Nombre demasiado corto';
    return null;
  }

  String? _validateTipoEmpresa(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escribe el tipo de empresa';
    }
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escribe un número de teléfono';
    }
    // 7 a 20 caracteres: dígitos, espacios, +, () y -
    final normalizado = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    final valido = RegExp(r'^\+?[0-9 ()\-]{7,20}$').hasMatch(normalizado);
    if (!valido) return 'Usa entre 7 y 20 caracteres (números, +, -, espacios)';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }
}

/// Indicador de fortaleza: barra de 4 segmentos.
class _PasswordStrengthBar extends StatefulWidget {
  const _PasswordStrengthBar({required this.controller});
  final TextEditingController controller;

  @override
  State<_PasswordStrengthBar> createState() => _PasswordStrengthBarState();
}

class _PasswordStrengthBarState extends State<_PasswordStrengthBar> {
  String _value = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (widget.controller.text != _value) {
      setState(() => _value = widget.controller.text);
    }
  }

  int get _score {
    var score = 0;
    if (_value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(_value)) score++;
    if (RegExp(r'[a-z]').hasMatch(_value)) score++;
    if (RegExp(r'\d').hasMatch(_value)) score++;
    return score.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final score = _value.isEmpty ? 0 : _score;
    final labels = const [
      'Muy débil',
      'Débil',
      'Media',
      'Fuerte',
      'Muy fuerte'
    ];
    final colors = const [
      AppColors.error,
      AppColors.error,
      AppColors.amber,
      AppColors.success,
      AppColors.success,
    ];

    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              decoration: BoxDecoration(
                color: i < score ? colors[score] : AppColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        const SizedBox(width: 10),
        Text(
          _value.isEmpty ? '' : labels[score],
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors[score],
          ),
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.orange,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                text: 'Acepto los ',
                style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                children: const [
                  TextSpan(
                    text: 'términos',
                    style: TextStyle(
                      color: AppColors.orangeText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'privacidad',
                    style: TextStyle(
                      color: AppColors.orangeText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Logo de Google (marca oficial, sin recolorear).
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(18, 18), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..isAntiAlias = true;

    final rect = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.06,
      size.width * 0.88,
      size.height * 0.88,
    );
    const startAngle = -0.35;
    const sweepAngle = 5.6;

    // Colores oficiales de la G de Google, en sus cuatro arcos.
    const colors = [
      Color(0xFF4285F4),
      Color(0xFF34A853),
      Color(0xFFFBBC05),
      Color(0xFFEA4335),
    ];
    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        rect,
        startAngle + (i * (sweepAngle / 4)),
        sweepAngle / 4,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}

/// Campo de fecha de nacimiento con selector de calendario.
class _FechaNacimientoField extends StatelessWidget {

  const _FechaNacimientoField({required this.fecha, required this.onChanged});
  final DateTime? fecha;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Fecha de nacimiento',
      button: true,
      child: InkWell(
        onTap: () async {
          final hoy = DateTime.now();
          final inicial = fecha ?? DateTime(hoy.year - 20, hoy.month, hoy.day);
          final elegida = await showDatePicker(
            context: context,
            initialDate: inicial,
            firstDate: DateTime(1950),
            lastDate: DateTime(hoy.year - 13, hoy.month, hoy.day),
            locale: const Locale('es'),
            helpText: 'Elige tu fecha de nacimiento',
          );
          onChanged(elegida);
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Fecha de nacimiento',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            fecha == null
                ? 'Toca para elegir'
                : '${fecha!.day.toString().padLeft(2, '0')}/'
                    '${fecha!.month.toString().padLeft(2, '0')}/'
                    '${fecha!.year}',
            style: TextStyle(
              fontSize: 16,
              color: fecha == null ? AppColors.inkMuted : AppColors.navy900,
            ),
          ),
        ),
      ),
    );
  }
}
