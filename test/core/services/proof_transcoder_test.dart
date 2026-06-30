import 'dart:io';

import 'package:arena/core/services/proof_transcoder.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBackend implements VideoTranscoderBackend {
  _FakeBackend(this._result, {this.throwError = false});
  final String? _result;
  final bool throwError;

  @override
  Future<String?> compressToLowRes(String inputPath) async {
    if (throwError) throw StateError('boom');
    return _result;
  }
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('transcoder_test');
  });
  tearDown(() => dir.delete(recursive: true));

  File write(String name, int bytes) {
    return File('${dir.path}/$name')
      ..writeAsBytesSync(List<int>.filled(bytes, 0x61));
  }

  test("proxy plus léger que l'original → renvoie le proxy", () async {
    final input = write('in.mp4', 1000);
    final out = write('out.mp4', 300);
    final t = ProofTranscoder(_FakeBackend(out.path));
    expect(await t.to360pProxy(input.path), out.path);
  });

  test('backend renvoie null → null (fallback amont)', () async {
    final input = write('in.mp4', 1000);
    final t = ProofTranscoder(_FakeBackend(null));
    expect(await t.to360pProxy(input.path), isNull);
  });

  test('backend lève → null (ne propage jamais)', () async {
    final input = write('in.mp4', 1000);
    final t = ProofTranscoder(_FakeBackend(null, throwError: true));
    expect(await t.to360pProxy(input.path), isNull);
  });

  test('proxy inexistant → null', () async {
    final input = write('in.mp4', 1000);
    final t = ProofTranscoder(_FakeBackend('${dir.path}/ghost.mp4'));
    expect(await t.to360pProxy(input.path), isNull);
  });

  test('proxy vide → null', () async {
    final input = write('in.mp4', 1000);
    final out = write('out.mp4', 0);
    final t = ProofTranscoder(_FakeBackend(out.path));
    expect(await t.to360pProxy(input.path), isNull);
  });

  test("proxy pas plus léger → null (garde l'original)", () async {
    final input = write('in.mp4', 500);
    final out = write('out.mp4', 800);
    final t = ProofTranscoder(_FakeBackend(out.path));
    expect(await t.to360pProxy(input.path), isNull);
  });
}
