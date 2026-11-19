import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/reporte.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import '../services/ubicacion_service.dart';

class NuevoReporteScreen extends StatefulWidget {
  const NuevoReporteScreen({super.key});
  @override
  State<NuevoReporteScreen> createState() => _NuevoReporteScreenState();
}

class _NuevoReporteScreenState extends State<NuevoReporteScreen> {
  final _nombre = TextEditingController();
  final _desc = TextEditingController();
  late final TextEditingController _contacto = TextEditingController(
      text: (Supabase.instance.client.auth.currentUser
                  ?.userMetadata?['telefono'] ??
              '')
          .toString());
  String _especie = 'perro';
  File? _foto;
  double? _lat, _lng;
  bool _guardando = false;

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _tomarFoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 70);
    if (x == null) return;
    // Copia la foto a una carpeta permanente de la app (evidencia local).
    final dir = await getApplicationDocumentsDirectory();
    final destino = p.join(dir.path, '${const Uuid().v4()}.jpg');
    await File(x.path).copy(destino);
    setState(() => _foto = File(destino));
  }

  Future<void> _leerGps() async {
    try {
      final pos = await UbicacionService.obtener();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      _msg(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _enviar() async {
    if (_nombre.text.trim().isEmpty ||
        _desc.text.trim().isEmpty ||
        _contacto.text.trim().isEmpty ||
        _foto == null ||
        _lat == null) {
      _msg('Completa nombre, descripción, contacto, foto y ubicación GPS.');
      return;
    }
    setState(() => _guardando = true);
    final r = Reporte(
      id: const Uuid().v4(),
      usuarioId: Supabase.instance.client.auth.currentUser!.id,
      nombreMascota: _nombre.text.trim(),
      especie: _especie,
      descripcion: _desc.text.trim(),
      contacto: _contacto.text.trim(),
      latitud: _lat!,
      longitud: _lng!,
      fotoLocal: _foto!.path,
      fecha: DateTime.now(),
    );
    await LocalDb.insertar(r); // 1) siempre se guarda local
    SyncService.sincronizarPendientes(); // 2) intenta enviar (si hay internet)
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reportar mascota perdida')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _nombre,
              decoration: const InputDecoration(
                  labelText: 'Nombre de la mascota',
                  border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _especie,
            decoration: const InputDecoration(
                labelText: 'Especie', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'perro', child: Text('Perro')),
              DropdownMenuItem(value: 'gato', child: Text('Gato')),
              DropdownMenuItem(value: 'otro', child: Text('Otro')),
            ],
            onChanged: (v) => setState(() => _especie = v ?? 'perro'),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Descripción (color, tamaño, collar, señas)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _contacto,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Teléfono de contacto',
                  border: OutlineInputBorder())),
          const SizedBox(height: 16),
          if (_foto != null)
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_foto!, height: 200, fit: BoxFit.cover)),
          OutlinedButton.icon(
              onPressed: _tomarFoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(_foto == null ? 'Tomar foto de la mascota' : 'Repetir foto')),
          const SizedBox(height: 12),
          if (_lat != null)
            Text(
                'Última ubicación: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'),
          OutlinedButton.icon(
              onPressed: _leerGps,
              icon: const Icon(Icons.my_location),
              label: Text(_lat == null
                  ? 'Capturar dónde se perdió (GPS)'
                  : 'Actualizar ubicación')),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _guardando ? null : _enviar,
              child: const Text('Publicar reporte')),
        ]),
      );
}
