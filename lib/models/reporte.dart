import 'package:flutter/material.dart';

class Reporte {
  final String id;
  final String usuarioId;
  final String nombreMascota;
  final String especie; // perro | gato | otro
  final String descripcion;
  final String contacto;
  final double latitud;
  final double longitud;
  final String fotoLocal; // ruta de la foto en el celular
  final DateTime fecha;
  String? fotoUrl; // URL en Supabase Storage una vez sincronizada
  String estado; // perdida | encontrada
  bool sincronizada;

  Reporte({
    required this.id,
    required this.usuarioId,
    required this.nombreMascota,
    required this.especie,
    required this.descripcion,
    required this.contacto,
    required this.latitud,
    required this.longitud,
    required this.fotoLocal,
    required this.fecha,
    this.fotoUrl,
    this.estado = 'perdida',
    this.sincronizada = false,
  });

  Map<String, dynamic> toDb() => {
        'id': id,
        'usuarioId': usuarioId,
        'nombreMascota': nombreMascota,
        'especie': especie,
        'descripcion': descripcion,
        'contacto': contacto,
        'latitud': latitud,
        'longitud': longitud,
        'fotoLocal': fotoLocal,
        'fecha': fecha.toIso8601String(),
        'fotoUrl': fotoUrl,
        'estado': estado,
        'sincronizada': sincronizada ? 1 : 0,
      };

  factory Reporte.fromDb(Map<String, dynamic> m) => Reporte(
        id: m['id'],
        usuarioId: m['usuarioId'],
        nombreMascota: m['nombreMascota'],
        especie: m['especie'],
        descripcion: m['descripcion'],
        contacto: m['contacto'],
        latitud: (m['latitud'] as num).toDouble(),
        longitud: (m['longitud'] as num).toDouble(),
        fotoLocal: m['fotoLocal'],
        fecha: DateTime.parse(m['fecha']),
        fotoUrl: m['fotoUrl'],
        estado: m['estado'],
        sincronizada: m['sincronizada'] == 1,
      );

  /// Fila para la tabla "reportes" de Supabase (PostgreSQL).
  Map<String, dynamic> toSupabase() => {
        'id': id,
        'usuario_id': usuarioId,
        'nombre_mascota': nombreMascota,
        'especie': especie,
        'descripcion': descripcion,
        'contacto': contacto,
        'latitud': latitud,
        'longitud': longitud,
        'estado': estado,
        'fecha': fecha.toUtc().toIso8601String(),
      };
}

String etiquetaEspecie(String e) {
  switch (e) {
    case 'perro':
      return 'Perro';
    case 'gato':
      return 'Gato';
    default:
      return 'Otro';
  }
}

String etiquetaEstado(String e) => e == 'encontrada' ? 'Encontrada' : 'Perdida';

Color colorEstado(String e) =>
    e == 'encontrada' ? const Color(0xFF1E8449) : const Color(0xFFC0392B);

String fmtFecha(String iso) {
  final f = DateTime.parse(iso).toLocal();
  final min = f.minute.toString().padLeft(2, '0');
  return '${f.day}/${f.month}/${f.year} ${f.hour}:$min';
}
