import 'package:contratos/contratos.dart' show Conservacao;

enum SituacaoEntrega { aguardando, disponivel, emRota, entregue }

final class EntregaInvalida implements Exception {
  EntregaInvalida(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}

typedef Destino = ({
  String cliente,
  String endereco,
  DateTime prometidoPara,
  List<Conservacao> itens,
});

final class Entrega {
  Entrega(this.pedidoId);

  final String pedidoId;
  Destino? _destino;
  bool _pronta = false;
  SituacaoEntrega _situacao = SituacaoEntrega.aguardando;

  SituacaoEntrega get situacao => _situacao;
  Destino get destino => _destino!;

  void registrarDestino(Destino d) {
    _destino ??= d;
    _liberarSePossivel();
  }

  void registrarPronta() {
    _pronta = true;
    _liberarSePossivel();
  }

  void iniciar() {
    if (_situacao != SituacaoEntrega.disponivel) {
      throw EntregaInvalida('Entrega $pedidoId não está disponível.');
    }
    _situacao = SituacaoEntrega.emRota;
  }

  void concluir() {
    if (_situacao != SituacaoEntrega.emRota) {
      throw EntregaInvalida('Entrega $pedidoId não está em rota.');
    }
    _situacao = SituacaoEntrega.entregue;
  }

  void _liberarSePossivel() {
    if (_situacao == SituacaoEntrega.aguardando && _pronta && _destino != null) {
      _situacao = SituacaoEntrega.disponivel;
    }
  }
}
