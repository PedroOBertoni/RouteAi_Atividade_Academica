import '../dominio/coordenada.dart';
import '../portas.dart';

/// Mapa simulado, sem chave nem internet. Posição fictícia, porém estável,
/// para qualquer endereço com número; sem número, não localiza.
final class MapaLocal implements Geocodificador, EstimadorDeTrechos {
  const MapaLocal({this.velocidadeKmH = 25, this.paradaMinutos = 2});
  final double velocidadeKmH;
  final int paradaMinutos;

  @override
  Future<Coordenada?> localizar(String endereco) async {
    final texto = endereco.trim().toLowerCase();
    if (!texto.contains(RegExp(r'\d'))) return null;
    var h = 7;
    for (final c in texto.codeUnits) {
      h = (h * 31 + c) & 0x3fffffff;
    }
    return Coordenada(
      centroDeFranca.lat + ((h % 1000) - 500) / 20000,
      centroDeFranca.lng + ((h ~/ 1000 % 1000) - 500) / 20000,
    );
  }

  @override
  Future<List<Duration>> estimar(Coordenada origem, List<Coordenada> paradas) async {
    var atual = origem;
    final trechos = <Duration>[];
    for (final p in paradas) {
      final minutos = atual.distanciaKm(p) / velocidadeKmH * 60 + paradaMinutos;
      trechos.add(Duration(seconds: (minutos * 60).round()));
      atual = p;
    }
    return trechos;
  }
}
