enum SituacaoComanda { aguardando, emPreparo, pronta, recusada }

final class OperacaoInvalida implements Exception {
  OperacaoInvalida(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}

final class Comanda {
  Comanda(this.pedidoId);

  final String pedidoId;
  List<String>? _itens;
  bool _pago = false;
  SituacaoComanda _situacao = SituacaoComanda.aguardando;

  List<String> get itens => List.unmodifiable(_itens ?? const []);
  SituacaoComanda get situacao => _situacao;

  void registrarItens(List<String> itens) => _itens ??= itens;
  void registrarPagamento() => _pago = true;

  /// Só inicia com os DOIS fatos conhecidos (itens e pagamento), em qualquer
  /// ordem de chegada. Devolve `true` apenas na transição.
  bool iniciarSePossivel() {
    if (_itens == null || !_pago || _situacao != SituacaoComanda.aguardando) return false;
    _situacao = SituacaoComanda.emPreparo;
    return true;
  }

  void concluir() => _sair(SituacaoComanda.pronta);
  void recusar() => _sair(SituacaoComanda.recusada);

  void _sair(SituacaoComanda destino) {
    if (_situacao != SituacaoComanda.emPreparo) {
      throw OperacaoInvalida('Comanda $pedidoId não está em preparo.');
    }
    _situacao = destino;
  }
}
