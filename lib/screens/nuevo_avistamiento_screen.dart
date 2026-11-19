import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/ubicacion_service.dart';

/// Permite a cualquier usuario avisar que vio a la mascota (requiere internet).
class NuevoAvistamientoScreen extends StatefulWidget {
  final String reporteId;
  const NuevoAvistamientoScreen({super.key, required this.reporteId});
  @override
  State<NuevoAvistamientoScreen> createState() =>
      _NuevoAvistamientoScreenState();
}

class _NuevoAvistamientoScreenState extends State<NuevoAvistamientoScreen> {
  final _sb = Supabase.instance.client;
  final _comentario = TextEditingController();
  File? _foto;
  double? _lat, _lng;
  bool _enviando = false;

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _tomarFoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 70);
    if (x != null) setState(() => _foto = File(x.path));
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
    if (_lat == null) {
      _msg('Captura primero tu ubicación GPS.');
      return;
    }
    setState(() => _enviando = true);
    try {
      String? url;
      if (_foto != null) {
        final ruta = 'avistamientos/${const Uuid().v4()}.jpg';
        await _sb.storage.from('fotos').upload(ruta, _foto!,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'image/jpeg'));
        url = _sb.storage.from('fotos').getPublicUrl(ruta);
      }
      await _sb.from('avistamientos').insert({
        'reporte_id': widget.reporteId,
        'usuario_id': _sb.auth.currentUser!.id,
        'comentario': _comentario.text.trim(),
        'latitud': _lat,
        'longitud': _lng,
        'foto_url': url,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg('No se pudo enviar (¿hay internet?): $e');
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Vi a esta mascota')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _comentario,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Comentario (cómo estaba, hacia dónde iba)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 16),
          if (_foto != null)
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_foto!, height: 200, fit: BoxFit.cover)),
          OutlinedButton.icon(
              onPressed: _tomarFoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(_foto == null ? 'Tomar foto (opcional)' : 'Repetir foto')),
          const SizedBox(height: 12),
          if (_lat != null)
            Text('Ubicación: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'),
          OutlinedButton.icon(
              onPressed: _leerGps,
              icon: const Icon(Icons.my_location),
              label: Text(_lat == null
                  ? 'Capturar dónde la vi (GPS)'
                  : 'Actualizar ubicación')),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _enviando ? null : _enviar,
              child: const Text('Enviar avistamiento')),
        ]),
      );
}
