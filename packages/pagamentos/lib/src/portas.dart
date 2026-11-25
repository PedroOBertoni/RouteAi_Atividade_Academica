import 'package:contratos/contratos.dart' show Dinheiro;

import 'dominio/pagamento.dart';

abstract interface class RepositorioPagamentos {
  Future<void> salvar(Pagamento pagamento);
  Future<Pagamento?> buscar(String pedidoId);
}

typedef RespostaGateway = ({bool aprovado, String motivo});

/// Operadora externa. Recusa é uma resposta; indisponibilidade é uma exceção
/// (e faz o barramento tentar de novo).
///
/// A [chave] de idempotência garante que repetir a chamada não cobre duas vezes.
abstract interface class GatewayPagamento {
  Future<RespostaGateway> cobrar({required String chave, required Dinheiro valor});
  Future<void> estornar({required String chave, required Dinheiro valor});
}
