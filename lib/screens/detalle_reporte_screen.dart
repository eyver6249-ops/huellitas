import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/reporte.dart';
import 'nuevo_avistamiento_screen.dart';

class DetalleReporteScreen extends StatefulWidget {
  final Map<String, dynamic> rep;
  const DetalleReporteScreen({super.key, required this.rep});
  @override
  State<DetalleReporteScreen> createState() => _DetalleReporteScreenState();
}

class _DetalleReporteScreenState extends State<DetalleReporteScreen> {
  final _sb = Supabase.instance.client;
  late String _estado = widget.rep['estado'];
  late final Stream<List<Map<String, dynamic>>> _avistamientos = _sb
      .from('avistamientos')
      .stream(primaryKey: ['id']).eq('reporte_id', widget.rep['id']);

  bool get _esDueno => widget.rep['usuario_id'] == _sb.auth.currentUser!.id;

  Future<void> _abrirMapa(num lat, num lng) async {
    await launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _marcarEncontrada() async {
    try {
      await _sb
          .from('reportes')
          .update({'estado': 'encontrada'}).eq('id', widget.rep['id']);
      setState(() => _estado = 'encontrada');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.rep;
    return Scaffold(
      appBar: AppBar(title: Text(d['nombre_mascota'])),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (d['foto_url'] != null)
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(d['foto_url'], height: 240, fit: BoxFit.cover)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: Text(
                  '${d['nombre_mascota']} · ${etiquetaEspecie(d['especie'])}',
                  style: Theme.of(context).textTheme.titleLarge)),
          Chip(
            label: Text(etiquetaEstado(_estado)),
            backgroundColor: colorEstado(_estado).withAlpha(40),
            labelStyle: TextStyle(
                color: colorEstado(_estado), fontWeight: FontWeight.bold),
          ),
        ]),
        const SizedBox(height: 8),
        Text(d['descripcion']),
        const SizedBox(height: 8),
        Text('Reportado: ${fmtFecha(d['fecha'])}'),
        SelectableText('Contacto: ${d['contacto']}'),
        const SizedBox(height: 8),
        Text(
            'Última ubicación: ${(d['latitud'] as num).toStringAsFixed(5)}, ${(d['longitud'] as num).toStringAsFixed(5)}'),
        OutlinedButton.icon(
            onPressed: () => _abrirMapa(d['latitud'], d['longitud']),
            icon: const Icon(Icons.map),
            label: const Text('Ver en el mapa')),
        const SizedBox(height: 12),
        if (_estado == 'perdida')
          FilledButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          NuevoAvistamientoScreen(reporteId: d['id']))),
              icon: const Icon(Icons.visibility),
              label: const Text('La vi (reportar avistamiento)')),
        if (_estado == 'perdida' && _esDueno)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
                onPressed: _marcarEncontrada,
                icon: const Icon(Icons.check_circle),
                label: const Text('Marcar como encontrada')),
          ),
        const Divider(height: 32),
        Text('Avistamientos', style: Theme.of(context).textTheme.titleMedium),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _avistamientos,
          builder: (c, snap) {
            final filas = (snap.data ?? []).toList()
              ..sort((a, b) =>
                  (b['fecha'] as String).compareTo(a['fecha'] as String));
            if (filas.isEmpty) {
              return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Todavía nadie la ha visto.'));
            }
            return Column(children: [
              for (final a in filas)
                Card(
                  child: ListTile(
                    leading: a['foto_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(a['foto_url'],
                                width: 56, height: 56, fit: BoxFit.cover))
                        : const Icon(Icons.visibility),
                    title: Text((a['comentario'] as String?)?.isNotEmpty == true
                        ? a['comentario']
                        : 'Avistamiento'),
                    subtitle: Text(fmtFecha(a['fecha'])),
                    trailing: IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: () => _abrirMapa(a['latitud'], a['longitud'])),
                  ),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}
