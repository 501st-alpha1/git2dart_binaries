import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef _GitLibgit2InitNative = ffi.Int Function();
typedef _GitLibgit2Init = int Function();
typedef _GitLibgit2ShutdownNative = ffi.Int Function();
typedef _GitLibgit2Shutdown = int Function();

void main() {
  test(
    'macOS dylibs are self-contained and loadable',
    () async {
      final libgit2 = File('macos/libgit2.dylib').absolute;

      expect(
        await libgit2.exists(),
        isTrue,
        reason: '${libgit2.path} must be present in macOS artifacts',
      );

      await _expectDylibId(libgit2, '@rpath/libgit2.dylib');

      final libgit2Deps = await _otool(<String>['-L', libgit2.path]);

      expect(libgit2Deps, isNot(contains('libssh2')));
      expect(libgit2Deps, isNot(contains('libcrypto')));
      expect(libgit2Deps, isNot(contains('libssl')));

      _expectNoHomebrewReferences(libgit2Deps);

      final openedLibgit2 = ffi.DynamicLibrary.open(libgit2.path);

      expect(openedLibgit2, isA<ffi.DynamicLibrary>());

      final init = openedLibgit2
          .lookupFunction<_GitLibgit2InitNative, _GitLibgit2Init>(
            'git_libgit2_init',
          );
      final shutdown = openedLibgit2
          .lookupFunction<_GitLibgit2ShutdownNative, _GitLibgit2Shutdown>(
            'git_libgit2_shutdown',
          );

      expect(init(), greaterThanOrEqualTo(0));
      expect(shutdown(), greaterThanOrEqualTo(0));
    },
    skip: Platform.isMacOS ? null : 'macOS packaging test',
  );

  test(
    'macOS package-root loader works in a plain Dart process',
    () async {
      final packageConfig = File('.dart_tool/package_config.json').absolute;
      expect(
        await packageConfig.exists(),
        isTrue,
        reason: '${packageConfig.path} must exist after pub get',
      );

      final tempDir = await Directory.systemTemp.createTemp(
        'git2dart_binaries_plain_dart_',
      );
      try {
        final script = File('${tempDir.path}/load_git2dart_binaries.dart');
        await script.writeAsString(r'''
import 'dart:io';

import 'package:git2dart_binaries/src/util.dart' as git2;

void main() {
  final initCount = git2.libgit2.git_libgit2_init();
  if (initCount < 1) {
    stderr.writeln('git_libgit2_init returned $initCount');
    exit(1);
  }

  git2.libgit2.git_libgit2_shutdown();
  git2.libgit2.git_libgit2_shutdown();
  stdout.writeln('plain-dart-libgit2-ok');
}
''');

        final result = await Process.run(
          _dartExecutable(),
          <String>['--packages=${packageConfig.path}', script.path],
          workingDirectory: Directory.current.path,
        ).timeout(const Duration(seconds: 30));

        expect(
          result.exitCode,
          0,
          reason:
              'plain Dart loader process failed or crashed.\n'
              'stdout:\n${result.stdout}\n'
              'stderr:\n${result.stderr}',
        );
        expect(result.stdout, contains('plain-dart-libgit2-ok'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    },
    skip: Platform.isMacOS ? null : 'macOS plain Dart loader regression test',
  );
}

Future<void> _expectDylibId(File dylib, String expectedId) async {
  final output = await _otool(<String>['-D', dylib.path]);
  expect(output, contains(expectedId));
}

String _dartExecutable() {
  final executable = File(Platform.resolvedExecutable).uri.pathSegments.last;
  return executable == 'dart' ? Platform.resolvedExecutable : 'dart';
}

void _expectNoHomebrewReferences(String otoolOutput) {
  expect(otoolOutput, isNot(contains('/opt/homebrew/')));
  expect(otoolOutput, isNot(contains('/usr/local/')));
}

Future<String> _otool(List<String> arguments) async {
  final result = await Process.run('otool', arguments);
  final output = '${result.stdout}${result.stderr}';

  if (result.exitCode != 0) {
    fail('otool ${arguments.join(' ')} failed:\n$output');
  }

  return output;
}
