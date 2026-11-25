import 'package:contratos/contratos.dart';

import '../dominio/pedido.dart';
import '../portas.dart';

typedef LinhaPedido = ({String produtoId, int quantidade});

final class ServicoPedidos {
  ServicoPedidos({
    required RepositorioPedidos repositorio,
    required ConsultaProduto produtos,
    required Publicador publicador,
    required String Function() novoId,
    DateTime Function() agora = DateTime.now,
    this.prazo = const Duration(minutes: 50),
  })  : _repositorio = repositorio,
        _produtos = produtos,
        _publicador = publicador,
        _novoId = novoId,
        _agora = agora;

  static const consumidor = 'pedidos';

  final RepositorioPedidos _repositorio;
  final ConsultaProduto _produtos;
  final Publicador _publicador;
  final String Function() _novoId;
  final DateTime Function() _agora;
  final Duration prazo;

  void assinarEventos(Assinador a) {
    _acompanhar<PagamentoAprovado>(a, PagamentoAprovado.nome, SituacaoPedido.pago);
    _acompanhar<PagamentoRecusado>(a, PagamentoRecusado.nome, SituacaoPedido.cancelado);
    _acompanhar<PreparoIniciado>(a, PreparoIniciado.nome, SituacaoPedido.emPreparo);
    _acompanhar<PedidoRecusado>(a, PedidoRecusado.nome, SituacaoPedido.cancelado);
    _acompanhar<PedidoPronto>(a, PedidoPronto.nome, SituacaoPedido.pronto);
    _acompanhar<SaiuParaEntrega>(a, SaiuParaEntrega.nome, SituacaoPedido.emRota);
    _acompanhar<EntregaConcluida>(a, EntregaConcluida.nome, SituacaoPedido.entregue);
  }

  /// O preço vem do catálogo, nunca do cliente.
  Future<Pedido> criar({
    required String cliente,
    required String endereco,
    required List<LinhaPedido> linhas,
  }) async {
    final itens = <ItemPedido>[];
    for (final l in linhas) {
      final p = await _produtos.buscar(l.produtoId) ??
          (throw PedidoInvalido('Produto inexistente: ${l.produtoId}'));
      itens.add(ItemPedido(
        produtoId: l.produtoId,
        nome: p.nome,
        quantidade: l.quantidade,
        precoUnitario: p.preco,
        conservacao: p.conservacao,
      ));
    }
    final pedido = Pedido(
      id: _novoId(),
      cliente: cliente,
      endereco: endereco,
      itens: itens,
      prometidoPara: _agora().add(prazo),
    );
    await _repositorio.salvar(pedido);
    await _publicador.publicar(PedidoCriado(
      pedidoId: pedido.id,
      cliente: pedido.cliente,
      endereco: pedido.endereco,
      itens: pedido.itens,
      total: pedido.total,
      prometidoPara: pedido.prometidoPara,
    ));
    return pedido;
  }

  Future<List<Pedido>> listar() => _repositorio.listar();

  void _acompanhar<E extends Evento>(Assinador a, String tipo, SituacaoPedido situacao) {
    a.assinar<E>(
      consumidor: consumidor,
      tipo: tipo,
      tratar: (e) async {
        final pedido = await _repositorio.buscar(e.pedidoId);
        if (pedido == null) return;
        pedido.avancarPara(situacao);
        await _repositorio.salvar(pedido);
      },
    );
  }
}
