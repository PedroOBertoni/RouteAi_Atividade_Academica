import 'dart:async';
import 'dart:collection';

import 'package:contratos/contratos.dart';

enum SituacaoMensagem { publicada, processada, falhou, morta }

/// Registro de observabilidade: o que aconteceu com cada mensagem.
final class RegistroMensagem {
  RegistroMensagem(this.situacao, this.tipo, this.pedidoId,
      {this.consumidor, this.tentativa, this.erro});
  final SituacaoMensagem situacao;
  final String tipo;
  final String pedidoId;
  final String? consumidor;
  final int? tentativa;
  final String? erro;
  final DateTime em = DateTime.now();
}

final class EstadoFila {
  EstadoFila(this.consumidor, this.pendentes, this.mortas, this.pausada);
  final String consumidor;
  final int pendentes;
  final int mortas;
  final bool pausada;
}

final class _Mensagem {
  _Mensagem(this.tipo, this.pedidoId, this.corpo);
  final String tipo;
  final String pedidoId;
  final String corpo;
}

final class _Fila {
  final tratadores = <String, List<Tratador<Evento>>>{};
  final pendentes = Queue<_Mensagem>();
  final mortas = <_Mensagem>[];
  bool rodando = false;
  bool pausada = false;
}

/// Barramento assíncrono: uma fila FIFO por consumidor, nova tentativa com
/// espera crescente e fila de mensagens mortas (DLQ).
///
/// Garantia: ao menos uma entrega, enquanto o processo estiver vivo.
final class BarramentoEmMemoria implements Barramento {
  BarramentoEmMemoria({
    this.maxTentativas = 3,
    this.esperaBase = const Duration(milliseconds: 200),
    this.tempoLimite = const Duration(seconds: 5),
  });

  final int maxTentativas;
  final Duration esperaBase;
  final Duration tempoLimite;

  final _codec = const CodecEventos();
  final _filas = <String, _Fila>{};
  final _registros = StreamController<RegistroMensagem>.broadcast();

  Stream<RegistroMensagem> get registros => _registros.stream;

  @override
  void assinar<E extends Evento>({
    required String consumidor,
    required String tipo,
    required Tratador<E> tratar,
  }) {
    final fila = _filas.putIfAbsent(consumidor, _Fila.new);
    fila.tratadores.putIfAbsent(tipo, () => []).add((e) => tratar(e as E));
  }

  /// Enfileira e retorna. Não espera consumidor algum.
  @override
  Future<void> publicar(Evento evento) async {
    final msg = _Mensagem(evento.tipo, evento.pedidoId, _codec.codificar(evento));
    _registrar(SituacaoMensagem.publicada, msg);
    for (final e in _filas.entries) {
      if (!e.value.tratadores.containsKey(msg.tipo)) continue;
      e.value.pendentes.add(msg);
      _acordar(e.key);
    }
  }

  void pausar(String consumidor) => _fila(consumidor).pausada = true;

  void retomar(String consumidor) {
    _fila(consumidor).pausada = false;
    _acordar(consumidor);
  }

  /// Devolve as mensagens mortas para as filas de origem.
  int reprocessarMortas() {
    var total = 0;
    for (final e in _filas.entries) {
      total += e.value.mortas.length;
      e.value.pendentes.addAll(e.value.mortas);
      e.value.mortas.clear();
      _acordar(e.key);
    }
    return total;
  }

  List<EstadoFila> estado() => [
        for (final e in _filas.entries)
          EstadoFila(e.key, e.value.pendentes.length, e.value.mortas.length, e.value.pausada),
      ];

  /// Completa quando não houver nada a processar (filas pausadas não contam).
  Future<void> aguardarOcioso() async {
    while (_filas.values.any((f) => f.rodando || (!f.pausada && f.pendentes.isNotEmpty))) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  _Fila _fila(String c) =>
      _filas[c] ?? (throw ArgumentError.value(c, 'consumidor', 'não existe'));

  void _acordar(String consumidor) {
    final fila = _filas[consumidor]!;
    if (fila.rodando || fila.pausada || fila.pendentes.isEmpty) return;
    fila.rodando = true;
    Timer.run(() => _drenar(consumidor, fila));
  }

  Future<void> _drenar(String consumidor, _Fila fila) async {
    while (fila.pendentes.isNotEmpty && !fila.pausada) {
      final msg = fila.pendentes.removeFirst();
      if (!await _entregar(consumidor, fila, msg)) fila.mortas.add(msg);
    }
    fila.rodando = false;
  }

  Future<bool> _entregar(String consumidor, _Fila fila, _Mensagem msg) async {
    for (var t = 1; t <= maxTentativas; t++) {
      try {
        for (final tratar in fila.tratadores[msg.tipo]!) {
          await tratar(_codec.decodificar(msg.corpo)).timeout(tempoLimite);
        }
        _registrar(SituacaoMensagem.processada, msg, consumidor: consumidor, tentativa: t);
        return true;
      } catch (e) {
        _registrar(SituacaoMensagem.falhou, msg,
            consumidor: consumidor, tentativa: t, erro: '$e');
        if (t < maxTentativas) await Future<void>.delayed(esperaBase * (1 << (t - 1)));
      }
    }
    _registrar(SituacaoMensagem.morta, msg, consumidor: consumidor);
    return false;
  }

  void _registrar(SituacaoMensagem s, _Mensagem m,
          {String? consumidor, int? tentativa, String? erro}) =>
      _registros.add(RegistroMensagem(s, m.tipo, m.pedidoId,
          consumidor: consumidor, tentativa: tentativa, erro: erro));
}
