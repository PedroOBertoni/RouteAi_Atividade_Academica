import 'package:catalogo/catalogo.dart';
import 'package:contratos/contratos.dart';
import 'package:cozinha/cozinha.dart';
import 'package:entregas/entregas.dart';
import 'package:mensageria/mensageria.dart';
import 'package:notificacoes/notificacoes.dart';
import 'package:pagamentos/pagamentos.dart';
import 'package:pedidos/pedidos.dart';

/// Raiz de composição: único lugar que conhece todos os módulos e escolhe as
/// implementações concretas de cada porta.
final class Plataforma {
  Plataforma({
    BarramentoEmMemoria? barramento,
    Geocodificador geocodificador = const MapaLocal(),
    EstimadorDeTrechos estimador = const MapaLocal(),
    DateTime Function() agora = DateTime.now,
  }) : barramento = barramento ?? BarramentoEmMemoria() {
    pedidos = ServicoPedidos(
      repositorio: PedidosEmMemoria(),
      produtos: _ProdutosDoCatalogo(cardapio),
      publicador: this.barramento,
      novoId: () => 'P${(++_sequencia).toString().padLeft(3, '0')}',
      agora: agora,
    );
    pagamentos = ServicoPagamentos(
      repositorio: PagamentosEmMemoria(),
      gateway: gateway,
      publicador: this.barramento,
    );
    cozinha = ServicoCozinha(repositorio: ComandasEmMemoria(), publicador: this.barramento);
    entregas = ServicoEntregas(
      repositorio: EntregasEmMemoria(),
      geocodificador: geocodificador,
      estimador: estimador,
      publicador: this.barramento,
      agora: agora,
    );

    pedidos.assinarEventos(this.barramento);
    pagamentos.assinarEventos(this.barramento);
    cozinha.assinarEventos(this.barramento);
    entregas.assinarEventos(this.barramento);
    ServicoNotificacoes(canal).assinarEventos(this.barramento);
  }

  final BarramentoEmMemoria barramento;
  final gateway = GatewaySimulado();
  final canal = CanalEmMemoria();
  final cardapio = Cardapio(const [
    Produto('pizza', 'Pizza calabresa', Dinheiro(4990), Conservacao.quente),
    Produto('burger', 'Hambúrguer artesanal', Dinheiro(3250), Conservacao.quente),
    Produto('acai', 'Açaí 500 ml', Dinheiro(1890), Conservacao.congelado),
    Produto('refri', 'Refrigerante 2 L', Dinheiro(1200), Conservacao.ambiente),
  ]);

  late final ServicoPedidos pedidos;
  late final ServicoPagamentos pagamentos;
  late final ServicoCozinha cozinha;
  late final ServicoEntregas entregas;
  var _sequencia = 0;
}

/// Ponte entre a porta de Pedidos e o módulo Catálogo.
final class _ProdutosDoCatalogo implements ConsultaProduto {
  _ProdutosDoCatalogo(this._cardapio);
  final Cardapio _cardapio;

  @override
  Future<ProdutoOfertado?> buscar(String produtoId) async {
    final p = _cardapio.buscar(produtoId);
    return p == null
        ? null
        : ProdutoOfertado(nome: p.nome, preco: p.preco, conservacao: p.conservacao);
  }
}
