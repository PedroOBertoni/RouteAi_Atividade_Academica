import 'dart:convert';
import 'dart:io';

import 'package:contratos/contratos.dart' show Json;
import 'package:cozinha/cozinha.dart' show OperacaoInvalida;
import 'package:entregas/entregas.dart' show EntregaInvalida, centroDeFranca;
import 'package:mensageria/mensageria.dart' show RegistroMensagem;
import 'package:pagamentos/pagamentos.dart' show ModoGateway;
import 'package:pedidos/pedidos.dart' show PedidoInvalido;

import 'composicao.dart';

/// Adaptador HTTP: traduz requisições em chamadas aos módulos e nada mais.
final class Servidor {
  Servidor(this._p, {required String painelHtml}) : _painel = painelHtml;

  final Plataforma _p;
  final String _painel;

  Future<HttpServer> iniciar({int porta = 8080}) async {
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, porta);
    http.listen(_atender);
    return http;
  }

  Future<void> _atender(HttpRequest req) async {
    final caminho = req.uri.pathSegments;
    if (req.method == 'GET' && caminho.isEmpty) {
      req.response
        ..headers.contentType = ContentType.html
        ..write(_painel);
      return req.response.close();
    }
    if (req.method == 'GET' && req.uri.path == '/api/eventos') return _transmitir(req);

    int status;
    Object? corpo;
    try {
      (status, corpo) = await _rotear(req, caminho);
    } on PedidoInvalido catch (e) {
      (status, corpo) = (422, {'erro': e.mensagem});
    } on OperacaoInvalida catch (e) {
      (status, corpo) = (409, {'erro': e.mensagem});
    } on EntregaInvalida catch (e) {
      (status, corpo) = (409, {'erro': e.mensagem});
    } on ArgumentError catch (_) {
      (status, corpo) = (404, {'erro': 'Recurso inexistente.'});
    } on FormatException catch (_) {
      (status, corpo) = (400, {'erro': 'Requisição inválida.'});
    } on TypeError catch (_) {
      (status, corpo) = (400, {'erro': 'Requisição inválida.'});
    } catch (e) {
      stderr.writeln(e);
      (status, corpo) = (500, {'erro': 'Erro interno.'});
    }
    req.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(corpo));
    await req.response.close();
  }

  Future<(int, Object?)> _rotear(HttpRequest req, List<String> c) async {
    switch ((req.method, c)) {
      case ('GET', ['api', 'cardapio']):
        return (200, [
          for (final p in _p.cardapio.listar())
            {'id': p.id, 'nome': p.nome, 'preco': '${p.preco}'},
        ]);

      case ('GET', ['api', 'estado']):
        return (200, await _estado());

      case ('POST', ['api', 'pedidos']):
        final j = await _corpo(req);
        final pedido = await _p.pedidos.criar(
          cliente: j['cliente'] as String,
          endereco: j['endereco'] as String,
          linhas: [
            for (final l in j['itens'] as List)
              (produtoId: (l as Map)['produtoId'] as String, quantidade: l['quantidade'] as int),
          ],
        );
        // 202: aceito. Cobrança, preparo e entrega acontecem depois.
        return (202, {'id': pedido.id, 'total': '${pedido.total}'});

      case ('POST', ['api', 'cozinha', final id, 'pronto']):
        await _p.cozinha.concluir(id);
        return (202, {'ok': true});

      case ('POST', ['api', 'cozinha', final id, 'recusar']):
        await _p.cozinha.recusar(id, 'item em falta');
        return (202, {'ok': true});

      case ('POST', ['api', 'entregas', 'despachar']):
        final rota = await _p.entregas.despachar(centroDeFranca);
        return (200, {
          'paradas': [
            for (final p in rota.paradas)
              {
                'pedidoId': p.parada.pedidoId,
                'endereco': p.parada.endereco,
                'prioridade': p.parada.prioridade.name,
                'chegada': p.chegadaEstimada.toIso8601String(),
                'atrasa': p.atrasa,
              },
          ],
          'naoLocalizados': rota.naoLocalizados,
        });

      case ('POST', ['api', 'entregas', final id, 'concluir']):
        await _p.entregas.concluir(id);
        return (202, {'ok': true});

      case ('POST', ['api', 'filas', final nome, 'pausar']):
        _p.barramento.pausar(nome);
        return (200, {'ok': true});

      case ('POST', ['api', 'filas', final nome, 'retomar']):
        _p.barramento.retomar(nome);
        return (200, {'ok': true});

      case ('POST', ['api', 'mortas', 'reprocessar']):
        return (200, {'reprocessadas': _p.barramento.reprocessarMortas()});

      case ('POST', ['api', 'gateway', final modo]):
        _p.gateway.modo = ModoGateway.values.byName(modo);
        return (200, {'modo': modo});
    }
    return (404, {'erro': 'Rota inexistente.'});
  }

  Future<Json> _estado() async => {
        'pedidos': [
          for (final p in await _p.pedidos.listar())
            {
              'id': p.id,
              'cliente': p.cliente,
              'total': '${p.total}',
              'situacao': p.situacao.name,
            },
        ],
        'comandas': [
          for (final c in await _p.cozinha.listar())
            {'id': c.pedidoId, 'itens': c.itens, 'situacao': c.situacao.name},
        ],
        'entregas': [
          for (final e in await _p.entregas.listar())
            {'id': e.pedidoId, 'situacao': e.situacao.name},
        ],
        'filas': [
          for (final f in _p.barramento.estado())
            {
              'nome': f.consumidor,
              'pendentes': f.pendentes,
              'mortas': f.mortas,
              'pausada': f.pausada,
            },
        ],
        'avisos': [
          for (final a in _p.canal.enviados) {'id': a.pedidoId, 'texto': a.texto},
        ],
        'gateway': _p.gateway.modo.name,
      };

  /// Server-Sent Events com tudo que passa pelo barramento.
  Future<void> _transmitir(HttpRequest req) async {
    final r = req.response
      ..bufferOutput = false
      ..headers.set('Content-Type', 'text/event-stream; charset=utf-8')
      ..headers.set('Cache-Control', 'no-cache');
    r.write(': ok\n\n');
    final inscricao = _p.barramento.registros.listen((x) => r.write('data: ${_linha(x)}\n\n'));
    try {
      await r.done;
    } catch (_) {
      // Navegador fechou a conexão.
    } finally {
      await inscricao.cancel();
    }
  }

  String _linha(RegistroMensagem x) => jsonEncode({
        'em': x.em.toIso8601String(),
        'situacao': x.situacao.name,
        'tipo': x.tipo,
        'pedidoId': x.pedidoId,
        'consumidor': x.consumidor,
        'tentativa': x.tentativa,
        'erro': x.erro,
      });

  Future<Json> _corpo(HttpRequest req) async =>
      jsonDecode(await utf8.decoder.bind(req).join()) as Json;
}
