import 'package:contratos/contratos.dart';
import 'package:cozinha/cozinha.dart';
import 'package:entregas/entregas.dart';
import 'package:mensageria/mensageria.dart';
import 'package:notificacoes/notificacoes.dart';
import 'package:pagamentos/pagamentos.dart';
import 'package:pedidos/pedidos.dart';
import 'package:test/test.dart';

/// Cada teste comprova uma linha da análise de conascência do documento.
void main() {
  final agora = DateTime(2026, 11, 26, 19);

  PedidoCriado criado([String id = 'P1']) => PedidoCriado(
        pedidoId: id,
        cliente: 'Ana',
        endereco: 'Rua A 10',
        itens: const [
          ItemPedido(
            produtoId: 'pizza',
            nome: 'Pizza',
            quantidade: 1,
            precoUnitario: Dinheiro(4990),
            conservacao: Conservacao.quente,
          ),
        ],
        total: const Dinheiro(4990),
        prometidoPara: agora,
      );

  BarramentoEmMemoria barramento({Duration limite = const Duration(seconds: 5)}) =>
      BarramentoEmMemoria(esperaBase: const Duration(milliseconds: 1), tempoLimite: limite);

  test('identidade: o consumidor recebe cópia, não a instância publicada', () async {
    final b = barramento();
    Evento? recebido;
    b.assinar<PedidoCriado>(
        consumidor: 'x', tipo: PedidoCriado.nome, tratar: (e) async => recebido = e);
    final original = criado();
    await b.publicar(original);
    await b.aguardarOcioso();
    expect(identical(recebido, original), isFalse);
    expect((recebido! as PedidoCriado).dados(), original.dados());
  });

  for (final pagamentoPrimeiro in [false, true]) {
    test('execução: cozinha inicia com qualquer ordem (pagamento 1º: $pagamentoPrimeiro)',
        () async {
      final b = barramento();
      final cozinha = ServicoCozinha(repositorio: ComandasEmMemoria(), publicador: b)
        ..assinarEventos(b);
      final eventos = <Evento>[
        criado(),
        PagamentoAprovado(pedidoId: 'P1', valor: const Dinheiro(4990)),
      ];
      final [primeiro, segundo] = pagamentoPrimeiro ? eventos.reversed.toList() : eventos;

      await b.publicar(primeiro);
      await b.aguardarOcioso();
      expect((await cozinha.listar()).single.situacao, SituacaoComanda.aguardando);

      await b.publicar(segundo);
      await b.aguardarOcioso();
      expect((await cozinha.listar()).single.situacao, SituacaoComanda.emPreparo);
    });
  }

  test('execução: evento atrasado não faz o pedido retroceder', () {
    final pedido = Pedido(
        id: 'P1', cliente: 'Ana', endereco: 'Rua A 10', itens: criado().itens, prometidoPara: agora)
      ..avancarPara(SituacaoPedido.pronto)
      ..avancarPara(SituacaoPedido.pago);
    expect(pedido.situacao, SituacaoPedido.pronto);
  });

  test('temporal: cobrança que estoura o tempo limite é repetida sem cobrar duas vezes', () async {
    final b = barramento(limite: const Duration(milliseconds: 20));
    final gateway = _GatewayLento();
    ServicoPagamentos(repositorio: PagamentosEmMemoria(), gateway: gateway, publicador: b)
        .assinarEventos(b);
    await b.publicar(criado());
    await b.aguardarOcioso();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(gateway.chamadas, 2);
    expect(gateway.real.cobrancas, 1);
  });

  test('temporal: consumidor lento não segura quem publica', () async {
    final b = barramento();
    b.assinar<PedidoCriado>(
        consumidor: 'lento',
        tipo: PedidoCriado.nome,
        tratar: (_) => Future.delayed(const Duration(milliseconds: 200)));
    final t = Stopwatch()..start();
    await b.publicar(criado());
    expect(t.elapsedMilliseconds, lessThan(100));
    await b.aguardarOcioso();
  });

  test('evento repetido: um aviso e uma cobrança', () async {
    final b = barramento();
    final canal = CanalEmMemoria();
    final gateway = GatewaySimulado();
    ServicoNotificacoes(canal).assinarEventos(b);
    ServicoPagamentos(repositorio: PagamentosEmMemoria(), gateway: gateway, publicador: b)
        .assinarEventos(b);
    await b.publicar(criado());
    await b.publicar(criado());
    await b.aguardarOcioso();
    expect(canal.enviados.map((a) => a.texto), ['Pedido recebido: R\$ 49,90.', 'Pagamento aprovado.']);
    expect(gateway.cobrancas, 1);
  });

  group('rota (defeitos herdados do RouteAI)', () {
    Parada parada(String id, double lng, Prioridade p) => Parada(
        pedidoId: id,
        endereco: id,
        posicao: Coordenada(-20.5, lng),
        prioridade: p,
        prometidoPara: agora);

    test('significado: a ordem segue o nome da prioridade', () {
      final ordem = ordenar(const Coordenada(-20.5, -47.40), [
        parada('perto', -47.41, Prioridade.podeEsperar),
        parada('longe', -47.50, Prioridade.urgente),
        parada('meio', -47.45, Prioridade.urgente),
      ]);
      expect(ordem.map((x) => x.pedidoId), ['meio', 'longe', 'perto']);
    });

    test('posição: cada parada leva a própria chegada, na ordem final', () {
      final ordem = [
        parada('a', -47.41, Prioridade.urgente),
        parada('b', -47.42, Prioridade.normal),
      ];
      final r = calcularChegadas(
          agora, ordem, const [Duration(minutes: 5), Duration(minutes: 7)]);
      expect(r[0].chegadaEstimada, agora.add(const Duration(minutes: 5)));
      expect(r[1].chegadaEstimada, agora.add(const Duration(minutes: 12)));
      expect(() => calcularChegadas(agora, ordem, const [Duration.zero]), throwsArgumentError);
    });

    test('congelado também é urgente; atraso vem antes de tudo', () {
      final folga = agora.add(const Duration(hours: 1));
      Prioridade c(Conservacao x, DateTime prazo) =>
          classificar(itens: [x], prometidoPara: prazo, agora: agora);
      expect(c(Conservacao.congelado, folga), Prioridade.urgente);
      expect(c(Conservacao.quente, folga), Prioridade.urgente);
      expect(c(Conservacao.ambiente, folga), Prioridade.podeEsperar);
      expect(c(Conservacao.ambiente, agora.add(const Duration(minutes: 10))), Prioridade.normal);
      expect(c(Conservacao.ambiente, agora.subtract(const Duration(minutes: 1))),
          Prioridade.atrasada);
    });

    test('adaptador do Google é trocável: mesma porta, resposta gravada', () async {
      final urls = <Uri>[];
      final google = GoogleMaps(
        chave: 'teste',
        buscar: (u) async {
          urls.add(u);
          return u.path.contains('directions')
              ? '{"status":"OK","routes":[{"legs":[{"duration":{"value":300}},{"duration":{"value":420}}]}]}'
              : '{"status":"OK","results":[{"geometry":{"location":{"lat":-20.53,"lng":-47.4}}}]}';
        },
      );
      expect(await google.localizar('Rua A, 10'), const Coordenada(-20.53, -47.4));
      expect(urls.single.queryParameters['query'], 'Rua A 10 Franca SP Brasil');
      expect(await google.estimar(centroDeFranca, const [Coordenada(1, 2), Coordenada(3, 4)]),
          const [Duration(minutes: 5), Duration(minutes: 7)]);
      expect(urls.last.queryParameters['waypoints'], '1.0,2.0');
    });
  });
}

/// Primeira chamada passa do tempo limite, mas termina depois.
final class _GatewayLento implements GatewayPagamento {
  final real = GatewaySimulado();
  int chamadas = 0;

  @override
  Future<RespostaGateway> cobrar({required String chave, required Dinheiro valor}) async {
    if (++chamadas == 1) await Future<void>.delayed(const Duration(milliseconds: 50));
    return real.cobrar(chave: chave, valor: valor);
  }

  @override
  Future<void> estornar({required String chave, required Dinheiro valor}) =>
      real.estornar(chave: chave, valor: valor);
}
