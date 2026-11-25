import 'evento.dart';
import 'valores.dart';

/// Publicado por Pedidos. Carrega o estado de que os consumidores precisam,
/// para que ninguém tenha de consultar Pedidos de forma síncrona.
final class PedidoCriado extends Evento {
  PedidoCriado({
    required super.pedidoId,
    required this.cliente,
    required this.endereco,
    required this.itens,
    required this.total,
    required this.prometidoPara,
    super.ocorridoEm,
  });
  static const nome = 'pedido.criado.v1';

  final String cliente;
  final String endereco;
  final List<ItemPedido> itens;
  final Dinheiro total;
  final DateTime prometidoPara;

  @override
  String get tipo => nome;
  @override
  Json dados() => {
        'cliente': cliente,
        'endereco': endereco,
        'itens': [for (final i in itens) i.toJson()],
        'totalCentavos': total.centavos,
        'prometidoPara': prometidoPara.toIso8601String(),
      };

  static PedidoCriado ler(String pedidoId, DateTime em, Json j) => PedidoCriado(
        pedidoId: pedidoId,
        ocorridoEm: em,
        cliente: j['cliente'] as String,
        endereco: j['endereco'] as String,
        itens: [
          for (final i in j['itens'] as List) ItemPedido.fromJson(i as Json),
        ],
        total: Dinheiro(j['totalCentavos'] as int),
        prometidoPara: DateTime.parse(j['prometidoPara'] as String),
      );
}

/// Publicado por Pagamentos.
final class PagamentoAprovado extends Evento {
  PagamentoAprovado({required super.pedidoId, required this.valor, super.ocorridoEm});
  static const nome = 'pagamento.aprovado.v1';
  final Dinheiro valor;
  @override
  String get tipo => nome;
  @override
  Json dados() => {'valorCentavos': valor.centavos};
  static PagamentoAprovado ler(String id, DateTime em, Json j) => PagamentoAprovado(
      pedidoId: id, ocorridoEm: em, valor: Dinheiro(j['valorCentavos'] as int));
}

/// Publicado por Pagamentos. Recusa é resultado de negócio, não falha técnica.
final class PagamentoRecusado extends Evento {
  PagamentoRecusado({required super.pedidoId, required this.motivo, super.ocorridoEm});
  static const nome = 'pagamento.recusado.v1';
  final String motivo;
  @override
  String get tipo => nome;
  @override
  Json dados() => {'motivo': motivo};
  static PagamentoRecusado ler(String id, DateTime em, Json j) =>
      PagamentoRecusado(pedidoId: id, ocorridoEm: em, motivo: j['motivo'] as String);
}

/// Publicado por Pagamentos ao compensar um pedido recusado pela cozinha.
final class PagamentoEstornado extends Evento {
  PagamentoEstornado({required super.pedidoId, required this.valor, super.ocorridoEm});
  static const nome = 'pagamento.estornado.v1';
  final Dinheiro valor;
  @override
  String get tipo => nome;
  @override
  Json dados() => {'valorCentavos': valor.centavos};
  static PagamentoEstornado ler(String id, DateTime em, Json j) => PagamentoEstornado(
      pedidoId: id, ocorridoEm: em, valor: Dinheiro(j['valorCentavos'] as int));
}

/// Publicado por Cozinha.
final class PreparoIniciado extends Evento {
  PreparoIniciado({required super.pedidoId, super.ocorridoEm});
  static const nome = 'preparo.iniciado.v1';
  @override
  String get tipo => nome;
  @override
  Json dados() => {};
  static PreparoIniciado ler(String id, DateTime em, Json j) =>
      PreparoIniciado(pedidoId: id, ocorridoEm: em);
}

/// Publicado por Cozinha.
final class PedidoPronto extends Evento {
  PedidoPronto({required super.pedidoId, super.ocorridoEm});
  static const nome = 'pedido.pronto.v1';
  @override
  String get tipo => nome;
  @override
  Json dados() => {};
  static PedidoPronto ler(String id, DateTime em, Json j) =>
      PedidoPronto(pedidoId: id, ocorridoEm: em);
}

/// Publicado por Cozinha; dispara o estorno (compensação da saga).
final class PedidoRecusado extends Evento {
  PedidoRecusado({required super.pedidoId, required this.motivo, super.ocorridoEm});
  static const nome = 'pedido.recusado.v1';
  final String motivo;
  @override
  String get tipo => nome;
  @override
  Json dados() => {'motivo': motivo};
  static PedidoRecusado ler(String id, DateTime em, Json j) =>
      PedidoRecusado(pedidoId: id, ocorridoEm: em, motivo: j['motivo'] as String);
}

/// Publicado por Entregas.
final class SaiuParaEntrega extends Evento {
  SaiuParaEntrega({required super.pedidoId, required this.chegadaEstimada, super.ocorridoEm});
  static const nome = 'entrega.iniciada.v1';
  final DateTime chegadaEstimada;
  @override
  String get tipo => nome;
  @override
  Json dados() => {'chegadaEstimada': chegadaEstimada.toIso8601String()};
  static SaiuParaEntrega ler(String id, DateTime em, Json j) => SaiuParaEntrega(
      pedidoId: id,
      ocorridoEm: em,
      chegadaEstimada: DateTime.parse(j['chegadaEstimada'] as String));
}

/// Publicado por Entregas.
final class EntregaConcluida extends Evento {
  EntregaConcluida({required super.pedidoId, super.ocorridoEm});
  static const nome = 'entrega.concluida.v1';
  @override
  String get tipo => nome;
  @override
  Json dados() => {};
  static EntregaConcluida ler(String id, DateTime em, Json j) =>
      EntregaConcluida(pedidoId: id, ocorridoEm: em);
}
