import 'package:geolocator/geolocator.dart';

class UbicacionService {
  /// Lee un punto GPS con alta precisión.
  static Future<Position> obtener() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('El GPS está desactivado. Actívalo e intenta de nuevo.');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
