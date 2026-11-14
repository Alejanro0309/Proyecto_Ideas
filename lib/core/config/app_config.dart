/// Configuración pública de RUMBO.
///
/// La dirección base es la de la app publicada (Netlify). Se puede cambiar al
/// compilar con `--dart-define=PUBLIC_BASE_URL=https://...`.
///
/// NUNCA se usa `Uri.base` ni `localhost` para armar el enlace del QR: el QR se
/// escanea desde OTRO teléfono, así que tiene que apuntar a la dirección
/// pública.
class AppConfig {
  /// Dirección pública de la app, SIN "/" al final.
  static const String publicBaseUrl = String.fromEnvironment(
    'PUBLIC_BASE_URL',
    defaultValue: 'https://TU-SITIO.netlify.app',
  );

  /// Enlace que va DENTRO del QR. La app web usa rutas con "#".
  static String cvUrl(String token) => '$publicBaseUrl/#/cv/$token';

  /// Enlace público de verificación de un logro.
  static String verificarUrl(String codigo) =>
      '$publicBaseUrl/#/verificar/$codigo';
}
