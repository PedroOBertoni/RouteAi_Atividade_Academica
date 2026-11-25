import 'package:contratos/contratos.dart' show Dinheiro;

import '../portas.dart';

enum ModoGateway { aprova, recusa, foraDoAr }

/// Operadora simulada, com comportamento trocável em tempo de execução.
final class GatewaySimulado implements GatewayPagamento {
  ModoGateway modo = ModoGateway.aprova;
  final _respostas = <String, RespostaGateway>{};

  /// Cobranças efetivamente realizadas (não conta repetições da mesma chave).
  int cobrancas = 0;

  @override
  Future<RespostaGateway> cobrar({required String chave, required Dinheiro valor}) async {
    if (modo == ModoGateway.foraDoAr) throw StateError('operadora fora do ar');
    return _respostas.putIfAbsent(chave, () {
      if (modo == ModoGateway.recusa) return (aprovado: false, motivo: 'saldo insuficiente');
      cobrancas++;
      return (aprovado: true, motivo: '');
    });
  }

  @override
  Future<void> estornar({required String chave, required Dinheiro valor}) async {
    if (modo == ModoGateway.foraDoAr) throw StateError('operadora fora do ar');
  }
}
