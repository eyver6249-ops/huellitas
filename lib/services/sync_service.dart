import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_db.dart';

/// Envía al backend (Supabase) los reportes guardados localmente cuando hay
/// internet: sube la foto al Storage y guarda la fila en PostgreSQL.
class SyncService {
  static bool _enCurso = false;

  static Future<int> sincronizarPendientes() async {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null || _enCurso) return 0;
    _enCurso = true;
    var enviados = 0;
    try {
      for (final r in await LocalDb.pendientes(user.id)) {
        try {
          final ruta = 'reportes/${r.id}.jpg';
          await sb.storage.from('fotos').upload(ruta, File(r.fotoLocal),
              fileOptions:
                  const FileOptions(upsert: true, contentType: 'image/jpeg'));
          final url = sb.storage.from('fotos').getPublicUrl(ruta);
          await sb.from('reportes').upsert({...r.toSupabase(), 'foto_url': url});
          await LocalDb.marcarSincronizada(r.id, url);
          enviados++;
        } catch (_) {
          // Sin conexión o error: se reintenta en la próxima sincronización.
        }
      }
    } finally {
      _enCurso = false;
    }
    return enviados;
  }

  /// Dispara la sincronización automáticamente al volver la conexión.
  static void escucharConexion() {
    Connectivity().onConnectivityChanged.listen((r) {
      if (!r.contains(ConnectivityResult.none)) sincronizarPendientes();
    });
  }
}
