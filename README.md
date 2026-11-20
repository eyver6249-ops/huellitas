# huellitas

A new Flutter project.
# Huellitas

App móvil (Flutter + Supabase) para reportar mascotas perdidas con GPS y foto.
Proyecto final de Optativa IV.

## Funciones
- Reportar una mascota perdida con foto, GPS y contacto
- Lista de reportes en tiempo real, con filtros
- Avistamientos de la comunidad (GPS, foto y comentario)
- Modo sin conexión: el reporte se guarda y se sincroniza después

## Tecnologías
Flutter, Dart, Supabase (PostgreSQL, Auth, Storage), SQLite.

## Cómo ejecutarlo
1. Crear un proyecto en Supabase y ejecutar `supabase/schema_mascotas.sql` en el SQL Editor.
2. Poner la URL y la clave en `lib/config.dart`.
3. `flutter pub get` y `flutter run`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
