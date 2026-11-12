import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/student_profile.dart';
import '../../../repositories/retos_repository.dart';
import '../widgets/rumbo_card.dart';

/// Perfil de empresa: `/empresa/perfil`.
class EmpresaPerfilScreen extends ConsumerStatefulWidget {
  const EmpresaPerfilScreen({super.key});

  @override
  ConsumerState<EmpresaPerfilScreen> createState() =>
      _EmpresaPerfilScreenState();
}

class _EmpresaPerfilScreenState extends ConsumerState<EmpresaPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  String _tipo = '';
  bool _cargado = false;
  bool _guardando = false;
  String? _error;

  static const _tipos = [
    'Tecnología',
    'Comercio',
    'Servicios',
    'Educación',
    'Salud',
    'Otro',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(studentProfileProvider);

    perfilAsync.whenData((p) {
      if (!_cargado && p != null) {
        _nombreCtrl.text = p.firstName ?? '';
        _telefonoCtrl.text = p.telefono ?? '';
        _tipo = p.tipoEmpresa ?? '';
        _cargado = true;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: RumboCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perfil de empresa',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          helperText: 'Entre 2 y 80 caracteres',
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.length < 2 || t.length > 80) {
                            return 'El nombre debe tener entre 2 y 80 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _tipos.contains(_tipo) ? _tipo : null,
                        items: [
                          for (final t in _tipos)
                            DropdownMenuItem(value: t, child: Text(t)),
                        ],
                        onChanged: (v) => setState(() => _tipo = v ?? ''),
                        decoration:
                            const InputDecoration(labelText: 'Tipo de empresa'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefonoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          helperText:
                              '7 a 20 caracteres (números, +, -, espacios)',
                        ),
                        validator: _validarTelefono,
                      ),
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Correo'),
                        child: Text(
                          perfilAsync.valueOrNull?.email ?? '—',
                          style: const TextStyle(color: AppColors.inkMuted),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _guardando ? null : _guardar,
                          child:
                              Text(_guardando ? 'Guardando…' : 'Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validarTelefono(String? value) {
    final t = (value ?? '').trim();
    if (t.isEmpty) return null;
    final normalizado = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    final valido = RegExp(r'^\+?[0-9 ()\-]{7,20}$').hasMatch(normalizado);
    if (!valido) return 'Usa entre 7 y 20 caracteres (números, +, -, espacios)';
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await ref.read(retosRepositoryProvider).actualizarPerfilEmpresa(
            nombre: _nombreCtrl.text.trim(),
            tipo: _tipo,
            telefono: _telefonoCtrl.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(studentProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(
          () => _error = traducirExcepcion(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
