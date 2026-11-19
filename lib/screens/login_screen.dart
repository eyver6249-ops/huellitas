import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _naranja = Color(0xFFE8743B);
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  bool _registro = false;
  bool _cargando = false;
  bool _verPass = false;

  String _mensaje(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) return 'Correo o contraseña incorrectos.';
      if (m.contains('already registered')) return 'Este correo ya está registrado.';
      if (m.contains('email not confirmed')) return 'Debes confirmar tu correo.';
      if (m.contains('password')) return 'La contraseña no es válida (mínimo 6 caracteres).';
      if (m.contains('email')) return 'El correo no es válido.';
      return e.message;
    }
    return 'No se pudo conectar. Revisa tu conexión a internet.';
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      if (_registro) {
        await AuthService.registrar(_nombre.text.trim(), _telefono.text.trim(),
            _correo.text.trim(), _pass.text);
      } else {
        await AuthService.login(_correo.text.trim(), _pass.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFC0392B),
            content: Text(_mensaje(e))));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  InputDecoration _deco(String label, IconData icono, {Widget? sufijo}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
        suffixIcon: sufijo,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE9DA), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset('assets/icono_app.png',
                        width: 96, height: 96),
                  ),
                  const SizedBox(height: 12),
                  const Text('Huellitas',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: _naranja)),
                  const Text('Ayudemos a las mascotas a volver a casa',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(children: [
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                    value: false, label: Text('Iniciar sesión')),
                                ButtonSegment(
                                    value: true, label: Text('Registrarme')),
                              ],
                              selected: {_registro},
                              onSelectionChanged: (s) =>
                                  setState(() => _registro = s.first),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_registro) ...[
                            TextFormField(
                              controller: _nombre,
                              textCapitalization: TextCapitalization.words,
                              decoration: _deco('Nombre completo', Icons.person),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Ingresa tu nombre'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _telefono,
                              keyboardType: TextInputType.phone,
                              decoration: _deco('Teléfono de contacto', Icons.phone),
                              validator: (v) => (v == null || v.trim().length < 6)
                                  ? 'Ingresa un teléfono válido'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _correo,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _deco('Correo electrónico', Icons.email),
                            validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch((v ?? '').trim())
                                ? null
                                : 'Ingresa un correo válido',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _pass,
                            obscureText: !_verPass,
                            decoration: _deco(
                              'Contraseña',
                              Icons.lock,
                              sufijo: IconButton(
                                icon: Icon(_verPass
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _verPass = !_verPass),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'La contraseña debe tener al menos 6 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: _cargando ? null : _enviar,
                              child: _cargando
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text(_registro
                                      ? 'Crear mi cuenta'
                                      : 'Entrar'),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
