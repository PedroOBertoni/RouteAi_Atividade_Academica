import 'package:contratos/contratos.dart';
import 'package:entregas/entregas.dart';
import 'package:mensageria/mensageria.dart';
import 'package:pagamentos/pagamentos.dart';
import 'package:pedidos/pedidos.dart';
import 'package:plataforma/plataforma.dart';
import 'package:test/test.dart';

void main() {
  late Plataforma p;

  setUp(() => p = Plataforma(
        barramento: BarramentoEmMemoria(esperaBase: const Duration(milliseconds: 1)),
      ));

  Future<Pedido> pedir({String endereco = 'Rua A 10', String produto = 'pizza'}) async {
    final pedido = await p.pedidos.criar(
      cliente: 'Ana',
      endereco: endereco,
      linhas: [(produtoId: produto, quantidade: 2)],
    );
    return pedido;
  }

  test('fluxo completo: do pedido à entrega', () async {
    final pedido = await pedir();
    expect(pedido.total, const Dinheiro(9980));
    await p.barramento.aguardarOcioso();
    expect(pedido.situacao, SituacaoPedido.emPreparo);

    await p.cozinha.concluir(pedido.id);
    await p.barramento.aguardarOcioso();
    expect(pedido.situacao, SituacaoPedido.pronto);

    final rota = await p.entregas.despachar(centroDeFranca);
    expect(rota.paradas.single.parada.pedidoId, pedido.id);
    await p.barramento.aguardarOcioso();
    expect(pedido.situacao, SituacaoPedido.emRota);

    await p.entregas.concluir(pedido.id);
    await p.barramento.aguardarOcioso();
    expect(pedido.situacao, SituacaoPedido.entregue);
    expect(p.canal.enviados.map((a) => a.texto), contains('Pedido entregue. Bom apetite!'));
  });

  test('assíncrono: criar o pedido não espera a cobrança', () async {
    final pedido = await pedir();
    expect(pedido.situacao, SituacaoPedido.aguardandoPagamento);
    expect(p.gateway.cobrancas, 0);
    await p.barramento.aguardarOcioso();
    expect(p.gateway.cobrancas, 1);
  });

  test('pagamento recusado cancela o pedido e a cozinha não prepara', () async {
    p.gateway.modo = ModoGateway.recusa;
    final pedido = await pedir();
    await p.barramento.aguardarOcioso();
    expect(pedido.situacao, SituacaoPedido.cancelado);
    expect(() => p.cozinha.concluir(pedido.id), throwsA(anything));
  });

  test('saga: recusa da cozinha cancela e estorna', () async {
    final pedido = await pedir();
    await p.barramento.aguardarOcioso();
    await p.cozinha.recusar(pedido.id, 'item em falta');
    await p.barramento.aguardarOcioso();
    expect(pedido.situacao, SituacaoPedido.cancelado);
    expect(p.canal.enviados.map((a) => a.texto), contains('Estorno de R\$ 99,80 realizado.'));
  });

  test('operadora fora do ar: vai para a DLQ, o pedido não se perde', () async {
    p.gateway.modo = ModoGateway.foraDoAr;
    final pedido = await pedir();
    await p.barramento.aguardarOcioso();
    final fila = p.barramento.estado().firstWhere((f) => f.consumidor == 'pagamentos');
    expect(fila.mortas, 1);
    expect(pedido.situacao, SituacaoPedido.aguardandoPagamento);

    p.gateway.modo = ModoGateway.aprova;
    expect(p.barramento.reprocessarMortas(), 1);
    await p.barramento.aguardarOcioso();
    expect(pedido.situacao, SituacaoPedido.emPreparo);
  });

  test('cozinha parada não derruba pedidos nem pagamentos', () async {
    p.barramento.pausar('cozinha');
    final pedido = await pedir();
    await p.barramento.aguardarOcioso();
    expect(pedido.situacao, SituacaoPedido.pago);

    p.barramento.retomar('cozinha');
    await p.barramento.aguardarOcioso();
    expect(pedido.situacao, SituacaoPedido.emPreparo);
  });

  test('endereço não localizado fica fora da rota e não embaralha as demais', () async {
    final a = await pedir(endereco: 'sem numero');
    final b = await pedir(endereco: 'Rua B 20');
    await p.barramento.aguardarOcioso();
    await p.cozinha.concluir(a.id);
    await p.cozinha.concluir(b.id);
    await p.barramento.aguardarOcioso();

    final rota = await p.entregas.despachar(centroDeFranca);
    expect(rota.naoLocalizados, [a.id]);
    expect(rota.paradas.single.parada.pedidoId, b.id);
    expect(rota.paradas.single.parada.endereco, 'Rua B 20');
  });

  test('evolução: módulo novo entra só assinando eventos', () async {
    final pontos = <String>[];
    p.barramento.assinar<PagamentoAprovado>(
      consumidor: 'fidelidade',
      tipo: PagamentoAprovado.nome,
      tratar: (e) async => pontos.add('${e.pedidoId}: ${e.valor.centavos ~/ 100}'),
    );
    final pedido = await pedir();
    await p.barramento.aguardarOcioso();
    expect(pontos, ['${pedido.id}: 99']);
    expect(pedido.situacao, SituacaoPedido.emPreparo);
  });

  test('pedido inválido é rejeitado na hora', () {
    expect(pedir(produto: 'nao-existe'), throwsA(isA<PedidoInvalido>()));
    expect(pedir(endereco: ' '), throwsA(isA<PedidoInvalido>()));
  });
}
