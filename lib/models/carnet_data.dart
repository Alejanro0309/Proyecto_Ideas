import 'package:equatable/equatable.dart';

/// Datos leídos del carnet mediante OCR.
class CarnetData extends Equatable {

  const CarnetData({this.cedula, this.name, this.carnet, this.rol});
  final String? cedula; // solo dígitos
  final String? name;
  final String? carnet;

  /// Rol que aparece impreso en el documento. Hoy solo se acepta `Estudiante`.
  final String? rol;

  bool get hasCedula => cedula != null && cedula!.isNotEmpty;

  /// El documento es un carnet de estudiante.
  bool get esEstudiante => rol == 'Estudiante';

  String get formattedCedula => formatCedula(cedula ?? '');

  static String formatCedula(String digits) => digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );

  @override
  List<Object?> get props => [cedula, name, carnet, rol];
}
