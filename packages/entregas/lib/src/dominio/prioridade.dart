import 'package:contratos/contratos.dart' show Conservacao;

/// No RouteAI eram os números 0 a 3, repetidos em quatro arquivos.
/// A ordem de declaração é a ordem de atendimento.
enum Prioridade { atrasada, urgente, normal, podeEsperar }

/// Regra única de prioridade.
Prioridade classificar({
  required Iterable<Conservacao> itens,
  required DateTime prometidoPara,
  required DateTime agora,
}) {
  if (agora.isAfter(prometidoPara)) return Prioridade.atrasada;
  if (itens.any((c) => c != Conservacao.ambiente)) return Prioridade.urgente;
  final folga = prometidoPara.difference(agora);
  return folga > const Duration(minutes: 40) ? Prioridade.podeEsperar : Prioridade.normal;
}
