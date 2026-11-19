import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _sb => Supabase.instance.client;

  static Future<void> login(String correo, String pass) =>
      _sb.auth.signInWithPassword(email: correo, password: pass);

  /// La fila en la tabla "usuarios" la crea un trigger en la base de datos.
  static Future<void> registrar(
      String nombre, String telefono, String correo, String pass) async {
    await _sb.auth.signUp(
        email: correo,
        password: pass,
        data: {'nombre': nombre, 'telefono': telefono});
  }

  static Future<void> logout() => _sb.auth.signOut();
}
