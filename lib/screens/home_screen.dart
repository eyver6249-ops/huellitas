import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reporte.dart';
import '../services/auth_service.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import 'detalle_reporte_screen.dart';
import 'nuevo_reporte_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sb = Supabase.instance.client;
  late final String _uid = _sb.auth.currentUser!.id;
  // Tiempo real: la lista se actualiza sola cuando alguien reporta.
  late final Stream<List<Map<String, dynamic>>> _stream =
      _sb.from('reportes').stream(primaryKey: ['id']);
  String _filtro = 'todas';

  Future<void> _nuevo() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NuevoReporteScreen()));
    if (mounted) setState(() {}); // refresca los pendientes locales
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Huellitas'), actions: [
          IconButton(
              tooltip: 'Sincronizar',
              icon: const Icon(Icons.sync),
              onPressed: () async {
                final n = await SyncService.sincronizarPendientes();
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sincronizados: $n')));
                }
              }),
          IconButton(
              icon: const Icon(Icons.logout), onPressed: AuthService.logout),
        ]),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _nuevo,
            icon: const Icon(Icons.add),
            label: const Text('Reportar')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'todas', label: Text('Todas')),
                ButtonSegment(value: 'perdida', label: Text('Perdidas')),
                ButtonSegment(value: 'encontrada', label: Text('Encontradas')),
              ],
              selected: {_filtro},
              onSelectionChanged: (s) => setState(() => _filtro = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (c, snap) {
                final filas = (snap.data ?? [])
                    .where((d) => _filtro == 'todas' || d['estado'] == _filtro)
                    .toList()
                  ..sort((a, b) =>
                      (b['fecha'] as String).compareTo(a['fecha'] as String));
                return ListView(children: [
                  FutureBuilder<List<Reporte>>(
                    future: LocalDb.pendientes(_uid),
                    builder: (c, s) => Column(children: [
                      for (final p in s.data ?? <Reporte>[])
                        ListTile(
                          leading:
                              const Icon(Icons.cloud_off, color: Colors.orange),
                          title: Text(p.nombreMascota),
                          subtitle: const Text(
                              'Guardado en el celular · pendiente de sincronizar'),
                        ),
                    ]),
                  ),
                  if (snap.hasData && filas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No hay reportes todavía')),
                    ),
                  for (final d in filas)
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: d['foto_url'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(d['foto_url'],
                                    width: 56, height: 56, fit: BoxFit.cover))
                            : const Icon(Icons.pets, size: 40),
                        title: Text(
                            '${d['nombre_mascota']} · ${etiquetaEspecie(d['especie'])}'),
                        subtitle: Text(d['descripcion'],
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Chip(
                          label: Text(etiquetaEstado(d['estado'])),
                          backgroundColor:
                              colorEstado(d['estado']).withAlpha(40),
                          labelStyle: TextStyle(
                              color: colorEstado(d['estado']),
                              fontWeight: FontWeight.bold),
                        ),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DetalleReporteScreen(rep: d))),
                      ),
                    ),
                ]);
              },
            ),
          ),
        ]),
      );
}
