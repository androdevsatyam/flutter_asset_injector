import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_asset_injector/flutter_asset_injector.dart';

const _pubspec =
    'name: test_app\n'
    'flutter:\n'
    '  uses-material-design: true\n';

void main() {
  late Directory tempDir;
  late Directory originalDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asset_injector_test_');
    originalDir = Directory.current;
  });

  tearDown(() {
    Directory.current = originalDir;
    for (final entity in tempDir.listSync(recursive: true)) {
      try {
        if (entity is Directory) {
          Process.runSync('chmod', ['755', entity.path]);
        } else {
          Process.runSync('chmod', ['644', entity.path]);
        }
      } catch (_) {}
    }
    tempDir.deleteSync(recursive: true);
  });

  void createFile(String path, [String content = 'x']) {
    final file = File(p.join(tempDir.path, path));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  void writePubspec(String content) {
    File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync(content);
  }

  String readPubspec() {
    return File(p.join(tempDir.path, 'pubspec.yaml')).readAsStringSync();
  }

  int runInDir([List<String> args = const []]) {
    Directory.current = tempDir;
    return generateAssets(args);
  }

  group('scan and inject', () {
    test('discovers directories containing files', () {
      createFile('assets/images/logo.png');
      createFile('assets/icons/home.svg');
      writePubspec(_pubspec);

      final count = runInDir();

      expect(count, equals(2));
      final result = readPubspec();
      expect(result, contains('assets/icons/'));
      expect(result, contains('assets/images/'));
    });

    test('discovers nested directories recursively', () {
      createFile('assets/images/launcher/icon.png');
      createFile('assets/images/notification/alert.png');
      createFile('assets/greetings/birthday/card.png');
      writePubspec(_pubspec);

      runInDir();

      final result = readPubspec();
      expect(result, contains('assets/greetings/birthday/'));
      expect(result, contains('assets/images/launcher/'));
      expect(result, contains('assets/images/notification/'));
    });

    test('uses custom folder name from args', () {
      createFile('resources/data/config.json');
      writePubspec(_pubspec);

      runInDir(['resources']);

      expect(readPubspec(), contains('resources/data/'));
    });

    test('excludes empty directories', () {
      Directory(
        p.join(tempDir.path, 'assets/empty'),
      ).createSync(recursive: true);
      createFile('assets/real/file.png');
      writePubspec(_pubspec);

      runInDir();

      final result = readPubspec();
      expect(result, contains('assets/real/'));
      expect(result, isNot(contains('empty')));
    });
  });

  group('hidden entry filtering', () {
    test('skips hidden files', () {
      createFile('assets/images/.DS_Store');
      createFile('assets/images/logo.png');
      writePubspec(_pubspec);

      runInDir();

      expect(readPubspec(), contains('assets/images/'));
    });

    test('skips hidden directories', () {
      createFile('assets/.git/config');
      createFile('assets/.idea/modules.xml');
      createFile('assets/images/logo.png');
      writePubspec(_pubspec);

      runInDir();

      final result = readPubspec();
      expect(result, contains('assets/images/'));
      expect(result, isNot(contains('.git')));
      expect(result, isNot(contains('.idea')));
    });

    test('excludes directory with only hidden files', () {
      createFile('assets/hidden_only/.gitkeep');
      createFile('assets/real/file.png');
      writePubspec(_pubspec);

      runInDir();

      final result = readPubspec();
      expect(result, isNot(contains('hidden_only')));
      expect(result, contains('assets/real/'));
    });
  });

  group('symlinks', () {
    test('does not follow symlinks', () {
      createFile('assets/dir/file.png');
      final link = Link(p.join(tempDir.path, 'assets/dir/loop'));
      link.createSync('../dir');
      writePubspec(_pubspec);

      runInDir();

      expect(readPubspec(), contains('assets/dir/'));
      link.deleteSync();
    });
  });

  group('asset merging', () {
    test('preserves asset paths from other folders', () {
      createFile('assets/images/logo.png');
      writePubspec(
        'name: test_app\n'
        'flutter:\n'
        '  assets:\n'
        '    - other/fonts/\n'
        '  uses-material-design: true\n',
      );

      runInDir();

      final result = readPubspec();
      expect(result, contains('other/fonts/'));
      expect(result, contains('assets/images/'));
    });

    test('deduplicates asset paths', () {
      createFile('assets/images/logo.png');
      writePubspec(
        'name: test_app\n'
        'flutter:\n'
        '  assets:\n'
        '    - assets/images/\n'
        '  uses-material-design: true\n',
      );

      runInDir();

      expect('assets/images/'.allMatches(readPubspec()).length, equals(1));
    });

    test('sorts paths naturally', () {
      createFile('assets/z/f.png');
      createFile('assets/a/f.png');
      createFile('assets/m/f.png');
      writePubspec(_pubspec);

      runInDir();

      final result = readPubspec();
      final a = result.indexOf('assets/a/');
      final m = result.indexOf('assets/m/');
      final z = result.indexOf('assets/z/');
      expect(a, lessThan(m));
      expect(m, lessThan(z));
    });
  });

  group('pubspec variations', () {
    test('creates flutter section when missing', () {
      createFile('assets/images/logo.png');
      writePubspec('name: test_app\nenvironment:\n  sdk: ^3.7.0\n');

      runInDir();

      final result = readPubspec();
      expect(result, contains('flutter'));
      expect(result, contains('assets/images/'));
    });

    test('handles flutter: null', () {
      createFile('assets/images/logo.png');
      writePubspec('name: test_app\nflutter:\n');

      runInDir();

      expect(readPubspec(), contains('assets/images/'));
    });

    test('preserves existing flutter config', () {
      createFile('assets/images/logo.png');
      writePubspec(
        'name: test_app\n'
        'flutter:\n'
        '  uses-material-design: true\n'
        '  generate: true\n'
        '  fonts:\n'
        '    - family: Custom\n'
        '      fonts:\n'
        '        - asset: fonts/Custom.ttf\n',
      );

      runInDir();

      final result = readPubspec();
      expect(result, contains('generate: true'));
      expect(result, contains('Custom'));
      expect(result, contains('assets/images/'));
    });
  });

  group('placeholder comments', () {
    test('replaces default placeholder with assets block', () {
      createFile('assets/images/logo.png');
      writePubspec(
        'name: test_app\n'
        'flutter:\n'
        '  uses-material-design: true\n'
        '\n'
        '  # To add assets to your application, add an assets section, like this:\n'
        '  # assets:\n'
        '  #   - images/a_dot_burr.jpeg\n'
        '  #   - images/a_dot_ham.jpeg\n',
      );

      runInDir();

      final result = readPubspec();
      expect(result, contains('assets/images/'));
      expect(result, isNot(contains('a_dot_burr')));
    });

    test('strips placeholder when assets key already exists', () {
      createFile('assets/images/logo.png');
      writePubspec(
        'name: test_app\n'
        'flutter:\n'
        '  uses-material-design: true\n'
        '  assets:\n'
        '    - other/existing/\n'
        '\n'
        '  # To add assets to your application, add an assets section, like this:\n'
        '  # assets:\n'
        '  #   - images/a_dot_burr.jpeg\n'
        '  #   - images/a_dot_ham.jpeg\n',
      );

      runInDir();

      final result = readPubspec();
      expect(result, contains('assets/images/'));
      expect(result, contains('other/existing/'));
      expect(result, isNot(contains('a_dot_burr')));
    });
  });

  group('idempotence', () {
    test('multiple runs produce no duplicates', () {
      createFile('assets/images/logo.png');
      createFile('assets/icons/home.png');
      writePubspec(_pubspec);

      for (var i = 0; i < 5; i++) {
        runInDir();
      }

      expect('assets/images/'.allMatches(readPubspec()).length, equals(1));
    });

    test('picks up new directories on re-run', () {
      createFile('assets/images/logo.png');
      writePubspec(_pubspec);
      runInDir();

      createFile('assets/new_dir/icon.png');
      runInDir();

      final result = readPubspec();
      expect(result, contains('assets/images/'));
      expect(result, contains('assets/new_dir/'));
    });

    test('removes deleted directories on re-run', () {
      createFile('assets/images/logo.png');
      createFile('assets/old/file.png');
      writePubspec(_pubspec);
      runInDir();

      Directory(p.join(tempDir.path, 'assets/old')).deleteSync(recursive: true);
      runInDir();

      final result = readPubspec();
      expect(result, contains('assets/images/'));
      expect(result, isNot(contains('old')));
    });
  });

  group('error handling', () {
    test('throws when folder does not exist', () {
      writePubspec('name: test_app\n');

      expect(
        () => runInDir(),
        throwsA(
          isA<AssetInjectorException>().having(
            (e) => e.message,
            'message',
            contains('folder not found'),
          ),
        ),
      );
    });

    test('throws when pubspec.yaml is missing', () {
      createFile('assets/images/logo.png');

      expect(
        () => runInDir(),
        throwsA(
          isA<AssetInjectorException>().having(
            (e) => e.message,
            'message',
            contains('pubspec.yaml not found'),
          ),
        ),
      );
    });

    test('throws when no visible files found', () {
      createFile('assets/.hidden');
      writePubspec('name: test_app\n');

      expect(
        () => runInDir(),
        throwsA(
          isA<AssetInjectorException>().having(
            (e) => e.message,
            'message',
            contains('No valid files'),
          ),
        ),
      );
    });

    test('throws when pubspec.yaml is read-only', () {
      createFile('assets/images/logo.png');
      writePubspec(_pubspec);
      Process.runSync('chmod', ['444', p.join(tempDir.path, 'pubspec.yaml')]);

      expect(
        () => runInDir(),
        throwsA(
          isA<AssetInjectorException>().having(
            (e) => e.message,
            'message',
            contains('Failed to write'),
          ),
        ),
      );

      Process.runSync('chmod', ['644', p.join(tempDir.path, 'pubspec.yaml')]);
    });

    test('skips unreadable directories gracefully', () {
      createFile('assets/readable/file.png');
      createFile('assets/locked/secret.png');
      writePubspec(_pubspec);
      Process.runSync('chmod', [
        '000',
        p.join(tempDir.path, 'assets', 'locked'),
      ]);

      runInDir();

      final result = readPubspec();
      expect(result, contains('assets/readable/'));
      expect(result, isNot(contains('locked')));

      Process.runSync('chmod', [
        '755',
        p.join(tempDir.path, 'assets', 'locked'),
      ]);
    });

    test('returns correct count', () {
      createFile('assets/a/f.png');
      createFile('assets/b/f.png');
      createFile('assets/c/f.png');
      writePubspec(_pubspec);

      expect(runInDir(), equals(3));
    });
  });
}
