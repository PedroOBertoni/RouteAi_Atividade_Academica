import 'dart:math';

/// Substitui o `LatLng` do Google Maps no domínio e o texto "lat,lng" que o
/// RouteAI montava em um ponto e desmontava em outros dois.
final class Coordenada {
  const Coordenada(this.lat, this.lng);
  final double lat;
  final double lng;

  double distanciaKm(Coordenada o) {
    const raio = 6371.0;
    double rad(double g) => g * pi / 180;
    final dLat = rad(o.lat - lat), dLng = rad(o.lng - lng);
    final a = pow(sin(dLat / 2), 2) +
        cos(rad(lat)) * cos(rad(o.lat)) * pow(sin(dLng / 2), 2);
    return 2 * raio * asin(sqrt(a));
  }

  @override
  bool operator ==(Object other) =>
      other is Coordenada && other.lat == lat && other.lng == lng;
  @override
  int get hashCode => Object.hash(lat, lng);
}

const centroDeFranca = Coordenada(-20.5386, -47.4008);
