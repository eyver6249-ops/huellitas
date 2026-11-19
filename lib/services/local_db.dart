import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/reporte.dart';

/// Almacenamiento local (SQLite). Permite crear reportes sin internet.
class LocalDb {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await openDatabase(
      join(await getDatabasesPath(), 'huellitas.db'),
      version: 1,
      onCreate: (d, v) => d.execute('''
        CREATE TABLE reportes(
          id TEXT PRIMARY KEY, usuarioId TEXT, nombreMascota TEXT,
          especie TEXT, descripcion TEXT, contacto TEXT,
          latitud REAL, longitud REAL, fotoLocal TEXT, fecha TEXT,
          fotoUrl TEXT, estado TEXT, sincronizada INTEGER)
      '''),
    );
    return _db!;
  }

  static Future<void> insertar(Reporte r) async => (await db)
      .insert('reportes', r.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);

  static Future<List<Reporte>> pendientes(String usuarioId) async {
    final r = await (await db).query('reportes',
        where: 'sincronizada = 0 AND usuarioId = ?', whereArgs: [usuarioId]);
    return r.map(Reporte.fromDb).toList();
  }

  static Future<void> marcarSincronizada(String id, String url) async =>
      (await db).update('reportes', {'sincronizada': 1, 'fotoUrl': url},
          where: 'id = ?', whereArgs: [id]);
}
