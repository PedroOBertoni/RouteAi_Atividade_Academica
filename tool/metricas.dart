import 'dart:io';

/// Mede o acoplamento entre pacotes (Richards & Ford, cap. 3).
/// Uso: dart run tool/metricas.dart   (na raiz do repositório)
///
/// Ca: pacotes que dependem dele   Ce: pacotes de que ele depende
/// I = Ce/(Ca+Ce)   A = tipos abstratos/total de tipos   D = |A + I - 1|
void main() {
  final pacotes = {
    for (final pai in ['packages', 'apps'])
      for (final d in Directory(pai).listSync().whereType<Directory>())
        d.uri.pathSegments.lastWhere((s) => s.isNotEmpty): d,
  };
  final usa = {
    for (final e in pacotes.entries)
      e.key: {
        for (final f in _fontes(e.value))
          for (final m in RegExp(r"^(?:import|export) 'package:(\w+)/", multiLine: true)
              .allMatches(f.readAsStringSync()))
            if (m.group(1) != e.key && pacotes.containsKey(m.group(1))) m.group(1)!,
      },
  };

  print('${'pacote'.padRight(14)}  Ca  Ce     I     A     D  linhas');
  for (final e in pacotes.entries) {
    final ce = usa[e.key]!.length;
    final ca = usa.values.where((u) => u.contains(e.key)).length;
    final codigo = _fontes(e.value).map((f) => f.readAsStringSync()).join('\n');
    final tipos = RegExp(r'^(?:abstract |final |base |interface |sealed )*(?:class|enum) ',
            multiLine: true)
        .allMatches(codigo)
        .length;
    final abstratos =
        RegExp(r'^(?:abstract|sealed) ', multiLine: true).allMatches(codigo).length;
    final i = ca + ce == 0 ? 0.0 : ce / (ca + ce);
    final a = tipos == 0 ? 0.0 : abstratos / tipos;
    final d = (a + i - 1).abs();
    print('${e.key.padRight(14)}  ${'$ca'.padLeft(2)}  ${'$ce'.padLeft(2)}'
        '  ${i.toStringAsFixed(2)}  ${a.toStringAsFixed(2)}  ${d.toStringAsFixed(2)}'
        '  ${'${codigo.split('\n').length}'.padLeft(6)}');
  }
}

Iterable<File> _fontes(Directory d) => ['lib', 'bin']
    .map((s) => Directory('${d.path}/$s'))
    .where((x) => x.existsSync())
    .expand((x) => x.listSync(recursive: true))
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));
