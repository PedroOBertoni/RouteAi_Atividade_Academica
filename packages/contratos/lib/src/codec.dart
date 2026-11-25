import 'dart:convert';

import 'evento.dart';
import 'eventos.dart';
import 'valores.dart';

typedef _Leitor = Evento Function(String pedidoId, DateTime em, Json dados);

/// Converte eventos de/para texto. Como o que trafega é texto, dois módulos
/// nunca compartilham a mesma instância (sem conascência de identidade).
final class CodecEventos {
  const CodecEventos();

  static const Map<String, _Leitor> _leitores = {
    PedidoCriado.nome: PedidoCriado.ler,
    PagamentoAprovado.nome: PagamentoAprovado.ler,
    PagamentoRecusado.nome: PagamentoRecusado.ler,
    PagamentoEstornado.nome: PagamentoEstornado.ler,
    PreparoIniciado.nome: PreparoIniciado.ler,
    PedidoPronto.nome: PedidoPronto.ler,
    PedidoRecusado.nome: PedidoRecusado.ler,
    SaiuParaEntrega.nome: SaiuParaEntrega.ler,
    EntregaConcluida.nome: EntregaConcluida.ler,
  };

  String codificar(Evento e) => jsonEncode({
        'id': e.id,
        'tipo': e.tipo,
        'pedidoId': e.pedidoId,
        'ocorridoEm': e.ocorridoEm.toIso8601String(),
        'dados': e.dados(),
      });

  Evento decodificar(String texto) {
    final j = jsonDecode(texto) as Json;
    final ler = _leitores[j['tipo']] ??
        (throw FormatException('Tipo de evento desconhecido: ${j['tipo']}'));
    return ler(
      j['pedidoId'] as String,
      DateTime.parse(j['ocorridoEm'] as String),
      j['dados'] as Json,
    );
  }
}
