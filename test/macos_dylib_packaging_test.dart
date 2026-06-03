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
      final File libgit2 = File('macos/libgit2.dylib').absolute;
      final File libssh2 = File('macos/libssh2.1.dylib').absolute;
      final File libcrypto = File('macos/libcrypto.3.dylib').absolute;

      for (final File dylib in <File>[libgit2, libssh2, libcrypto]) {
        expect(
          dylib.existsSync(),
          isTrue,
          reason: '${dylib.path} must be present in macOS artifacts',
        );
      }

      await _expectDylibId(libgit2, '@rpath/libgit2.dylib');
      await _expectDylibId(libssh2, '@rpath/libssh2.1.dylib');
      await _expectDylibId(libcrypto, '@rpath/libcrypto.3.dylib');

      final String libgit2Deps = await _otool(<String>['-L', libgit2.path]);
      final String libssh2Deps = await _otool(<String>['-L', libssh2.path]);
      final String libcryptoDeps = await _otool(<String>['-L', libcrypto.path]);

      expect(libgit2Deps, contains('@rpath/libssh2.1.dylib'));
      expect(libssh2Deps, contains('@rpath/libcrypto.3.dylib'));

      _expectNoHomebrewReferences(libgit2Deps);
      _expectNoHomebrewReferences(libssh2Deps);
      _expectNoHomebrewReferences(libcryptoDeps);

      final ffi.DynamicLibrary openedLibcrypto = ffi.DynamicLibrary.open(
        libcrypto.path,
      );
      final ffi.DynamicLibrary openedLibssh2 = ffi.DynamicLibrary.open(
        libssh2.path,
      );
      final ffi.DynamicLibrary openedLibgit2 = ffi.DynamicLibrary.open(
        libgit2.path,
      );

      expect(openedLibcrypto, isA<ffi.DynamicLibrary>());
      expect(openedLibssh2, isA<ffi.DynamicLibrary>());
      expect(openedLibgit2, isA<ffi.DynamicLibrary>());

      final _GitLibgit2Init init = openedLibgit2
          .lookupFunction<_GitLibgit2InitNative, _GitLibgit2Init>(
            'git_libgit2_init',
          );
      final _GitLibgit2Shutdown shutdown = openedLibgit2
          .lookupFunction<_GitLibgit2ShutdownNative, _GitLibgit2Shutdown>(
            'git_libgit2_shutdown',
          );

      expect(init(), greaterThanOrEqualTo(0));
      expect(shutdown(), greaterThanOrEqualTo(0));
    },
    skip: Platform.isMacOS ? null : 'macOS packaging test',
  );
}

Future<void> _expectDylibId(File dylib, String expectedId) async {
  final String output = await _otool(<String>['-D', dylib.path]);
  expect(output, contains(expectedId));
}

void _expectNoHomebrewReferences(String otoolOutput) {
  expect(otoolOutput, isNot(contains('/opt/homebrew/')));
  expect(otoolOutput, isNot(contains('/usr/local/')));
}

Future<String> _otool(List<String> arguments) async {
  final ProcessResult result = await Process.run('otool', arguments);
  final String output = '${result.stdout}${result.stderr}';

  if (result.exitCode != 0) {
    fail('otool ${arguments.join(' ')} failed:\n$output');
  }

  return output;
}
