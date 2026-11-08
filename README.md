# Unimet App

App para estudiantes de la Universidad Metropolitana (Unimet, Venezuela).
Construida con **Flutter** + **Supabase**.

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.2.0
- Dart ≥ 3.2.0
- Cuenta de [Supabase](https://supabase.com) (plan gratuito funciona)
- Android Studio / Xcode para emuladores

## Configuración

1. **Clonar el repo** y entrar al proyecto:
   ```bash
   cd unimet_app
   ```

2. **Crear archivo `.env`** en la raíz del proyecto (ya existe un template):
   ```
   SUPABASE_URL=https://TU_PROYECTO.supabase.co
   SUPABASE_ANON_KEY=tu_anon_key_aqui
   ```

3. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

4. **Ejecutar la app**:
   ```bash
   flutter run
   ```

## Estructura del proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── config/
│   ├── app_constants.dart       # Constantes globales
│   ├── theme/
│   │   └── app_theme.dart       # Material 3 theme (claro/oscuro)
│   └── router/
│       └── app_router.dart      # GoRouter config
├── models/
│   ├── student_profile.dart     # Entidad StudentProfile
│   └── profile_repository.dart  # Repositorio (Supabase queries)
├── services/
│   ├── auth_service.dart        # Lógica de autenticación
│   └── scanner_service.dart     # Lógica de escaneo de carnet
├── controllers/
│   ├── providers.dart           # Riverpod providers globales
│   └── auth_controller.dart     # StateNotifier de auth
├── views/
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── scanner/
│   │   │   ├── scanner_screen.dart
│   │   │   └── scan_result_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   └── widgets/                 # Widgets reutilizables (próximas fases)
└── utils/
    └── validators.dart          # Validaciones de formularios
```

## Arquitectura

**MVC + Servicios** con **Riverpod** como gestor de estado.

| Capa | Responsabilidad |
|------|----------------|
| **Modelo** | Entidades (`StudentProfile`) y repositorios (queries a Supabase) |
| **Vista** | Pantallas y widgets. Sin lógica de negocio. |
| **Controlador** | `StateNotifier` + providers Riverpod. Maneja estado y eventos. |
| **Servicios** | Lógica de negocio (auth, escaneo). |

## Fases de desarrollo

- [x] Fase 1: Proyecto, dependencias y estructura
- [ ] Fase 2: Base de datos y seguridad (SQL, RLS)
- [ ] Fase 3: Autenticación completa
- [ ] Fase 4: Escaneo de carnet
- [ ] Fase 5: Interfaz completa con animaciones
- [ ] Fase 6: Pruebas y publicación

## Licencia
Proyecto universitario — uso privado.

