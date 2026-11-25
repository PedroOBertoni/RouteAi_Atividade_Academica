import 'dart:convert';

import '../dominio/coordenada.dart';
import '../portas.dart';

typedef BuscaHttp = Future<String> Function(Uri url);

/// Portado do `RouteService` do RouteAI: Places Text Search e Directions.
/// Diferença: aqui o Google só localiza e mede. Quem ordena é o domínio.
final class GoogleMaps implements Geocodificador, EstimadorDeTrechos {
  GoogleMaps({required String chave, required BuscaHttp buscar})
      : _chave = chave,
        _buscar = buscar;

  final String _chave;
  final BuscaHttp _buscar;

  static const _host = 'maps.googleapis.com';
  static const _limiteKm = 55.0;

  @override
  Future<Coordenada?> localizar(String endereco) async {
    final limpo = endereco.replaceAll(RegExp(r'[,\s]+'), ' ').trim();
    final consulta =
        limpo.toLowerCase().contains('franca') ? limpo : '$limpo Franca SP Brasil';
    final j = await _json('/maps/api/place/textsearch/json', {
      'query': consulta,
      'location': _texto(centroDeFranca),
      'radius': '25000',
    });
    final resultados = j['results'] as List? ?? const [];
    if (j['status'] == 'ZERO_RESULTS' || resultados.isEmpty && j['status'] == 'OK') return null;
    if (j['status'] != 'OK') throw StateError('Places: ${j['status']}');
    final loc = ((resultados.first as Map)['geometry'] as Map)['location'] as Map;
    final c = Coordenada((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
    return c.distanciaKm(centroDeFranca) <= _limiteKm ? c : null;
  }

  @override
  Future<List<Duration>> estimar(Coordenada origem, List<Coordenada> paradas) async {
    if (paradas.isEmpty) return const [];
    final meio = paradas.sublist(0, paradas.length - 1);
    final j = await _json('/maps/api/directions/json', {
      'origin': _texto(origem),
      'destination': _texto(paradas.last),
      if (meio.isNotEmpty) 'waypoints': meio.map(_texto).join('|'),
      'region': 'br',
    });
    if (j['status'] != 'OK') throw StateError('Directions: ${j['status']}');
    final pernas = ((j['routes'] as List).first as Map)['legs'] as List;
    return [
      for (final p in pernas)
        Duration(seconds: (((p as Map)['duration'] as Map)['value'] as num).toInt()),
    ];
  }

  String _texto(Coordenada c) => '${c.lat},${c.lng}';

  Future<Map<String, dynamic>> _json(String caminho, Map<String, String> q) async {
    final url = Uri.https(_host, caminho, {...q, 'language': 'pt-BR', 'key': _chave});
    return jsonDecode(await _buscar(url)) as Map<String, dynamic>;
  }
}
