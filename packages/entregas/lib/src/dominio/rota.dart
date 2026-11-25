import 'coordenada.dart';
import 'prioridade.dart';

final class Parada {
  const Parada({
    required this.pedidoId,
    required this.endereco,
    required this.posicao,
    required this.prioridade,
    required this.prometidoPara,
  });
  final String pedidoId;
  final String endereco;
  final Coordenada posicao;
  final Prioridade prioridade;
  final DateTime prometidoPara;
}

/// A parada carrega a própria chegada e a própria posição. No RouteAI eram
/// listas paralelas ligadas pelo índice.
final class ParadaPlanejada {
  const ParadaPlanejada(this.parada, this.chegadaEstimada);
  final Parada parada;
  final DateTime chegadaEstimada;
  bool get atrasa => chegadaEstimada.isAfter(parada.prometidoPara);
}

final class Rota {
  const Rota(this.paradas, {this.naoLocalizados = const []});
  final List<ParadaPlanejada> paradas;
  final List<String> naoLocalizados;
}

/// Rota aberta (não volta à origem): atende por prioridade e, dentro de cada
/// prioridade, vai sempre à parada mais próxima.
List<Parada> ordenar(Coordenada origem, Iterable<Parada> paradas) {
  final restantes = [...paradas];
  final ordem = <Parada>[];
  var atual = origem;
  while (restantes.isNotEmpty) {
    restantes.sort((a, b) {
      final p = a.prioridade.index.compareTo(b.prioridade.index);
      return p != 0
          ? p
          : atual.distanciaKm(a.posicao).compareTo(atual.distanciaKm(b.posicao));
    });
    final proxima = restantes.removeAt(0);
    ordem.add(proxima);
    atual = proxima.posicao;
  }
  return ordem;
}

/// Acumula os tempos dos trechos NA ORDEM FINAL das paradas.
List<ParadaPlanejada> calcularChegadas(
  DateTime saida,
  List<Parada> ordem,
  List<Duration> trechos,
) {
  if (trechos.length != ordem.length) {
    throw ArgumentError('Esperado um trecho por parada.');
  }
  var relogio = saida;
  return [
    for (final (i, p) in ordem.indexed)
      ParadaPlanejada(p, relogio = relogio.add(trechos[i])),
  ];
}
