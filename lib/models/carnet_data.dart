import 'package:equatable/equatable.dart';

/// Datos leídos del carnet mediante OCR.
class CarnetData extends Equatable {
  final String? cedula; // solo dígitos
  final String? name;
  final String? carnet;

  const CarnetData({this.cedula, this.name, this.carnet});

  bool get hasCedula => cedula != null && cedula!.isNotEmpty;

  String get formattedCedula => formatCedula(cedula ?? '');

  static String formatCedula(String digits) => digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );

  @override
  List<Object?> get props => [cedula, name, carnet];
}
