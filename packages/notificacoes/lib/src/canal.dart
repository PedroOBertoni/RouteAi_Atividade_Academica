/// Por onde o aviso sai (SMS, push, e-mail...).
abstract interface class CanalNotificacao {
  Future<void> enviar(String pedidoId, String texto);
}

typedef Aviso = ({String pedidoId, String texto, DateTime em});

final class CanalEmMemoria implements CanalNotificacao {
  final List<Aviso> enviados = [];
  @override
  Future<void> enviar(String pedidoId, String texto) async =>
      enviados.add((pedidoId: pedidoId, texto: texto, em: DateTime.now()));
}
