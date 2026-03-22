/// Automatically scan asset directories and inject them into `pubspec.yaml`.
///
/// Use [generateAssets] as the main entry point.
/// Catches errors with [AssetInjectorException].
library;

import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:yaml_edit/yaml_edit.dart';

/// Thrown when asset injection fails.
///
/// Contains a human-readable [message] describing the error.
class AssetInjectorException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// Creates an [AssetInjectorException] with the given [message].
  AssetInjectorException(this.message);

  @override
  String toString() => message;
}

/// Scans [folderName] (defaults to `assets`) for directories containing
/// visible files and injects them into the `pubspec.yaml` of the current
/// working directory.
///
/// Returns the number of asset paths injected.
///
/// Throws [AssetInjectorException] if:
/// - the asset folder does not exist
/// - no visible files are found
/// - `pubspec.yaml` is missing or not writable
int generateAssets(List<String> args) {
  final folderName = args.isNotEmpty ? args.first : 'assets';
  final rootPath = Directory.current.path;

  final scannedPaths = _scanAssetPaths(rootPath, folderName);
  final pubspecFile = _requirePubspecFile(rootPath);
  final pubspecContent = pubspecFile.readAsStringSync();

  final assets = _mergeAssets(pubspecContent, scannedPaths, folderName);
  final yaml = _buildYaml(pubspecContent, assets);

  _writeFile(pubspecFile, yaml);

  return scannedPaths.length;
}

Set<String> _scanAssetPaths(String rootPath, String folderName) {
  final directory = Directory(p.join(rootPath, folderName));

  if (!directory.existsSync()) {
    throw AssetInjectorException(
      '"$folderName" folder not found in the current directory: $rootPath',
    );
  }

  final Set<String> paths = {};
  _collectDirectories(directory, rootPath, paths);

  if (paths.isEmpty) {
    throw AssetInjectorException(
      'No valid files found in "$folderName" folder.',
    );
  }

  return paths;
}

void _collectDirectories(Directory dir, String rootPath, Set<String> results) {
  final List<FileSystemEntity> entries;
  try {
    entries = dir.listSync(followLinks: false);
  } on FileSystemException {
    return;
  }

  bool hasVisibleFiles = false;

  for (final entity in entries) {
    if (p.basename(entity.path).startsWith('.')) continue;

    if (entity is File) {
      hasVisibleFiles = true;
    } else if (entity is Directory) {
      _collectDirectories(entity, rootPath, results);
    }
  }

  if (hasVisibleFiles) {
    var rel = p.relative(dir.path, from: rootPath).replaceAll('\\', '/');
    if (!rel.endsWith('/')) rel += '/';
    results.add(rel);
  }
}

File _requirePubspecFile(String rootPath) {
  final file = File(p.join(rootPath, 'pubspec.yaml'));
  if (!file.existsSync()) {
    throw AssetInjectorException('pubspec.yaml not found at $rootPath');
  }
  return file;
}

void _writeFile(File file, String content) {
  try {
    file.writeAsStringSync(content);
  } on FileSystemException catch (e) {
    throw AssetInjectorException(
      'Failed to write pubspec.yaml: ${e.osError?.message ?? e.message}',
    );
  }
}

List<String> _mergeAssets(
  String pubspecContent,
  Set<String> scannedPaths,
  String folderName,
) {
  final existing = _parseExistingAssets(pubspecContent);
  final prefix = folderName.endsWith('/') ? folderName : '$folderName/';

  existing.removeWhere((e) => e.startsWith(prefix));
  existing.addAll(scannedPaths);

  return existing.toSet().toList()
    ..sort((a, b) => compareNatural(a.toLowerCase(), b.toLowerCase()));
}

List<String> _parseExistingAssets(String pubspecContent) {
  final editor = YamlEditor(pubspecContent);

  try {
    final flutter = editor.parseAt(['flutter']);
    if (flutter.value == null) return [];

    final assets = editor.parseAt(['flutter', 'assets']);
    if (assets.value is Iterable) {
      return [for (final v in assets.value as Iterable) v.toString()];
    }
  } catch (_) {}

  return [];
}

String _buildYaml(String pubspecContent, List<String> assets) {
  final editor = YamlEditor(pubspecContent);
  final state = _flutterState(editor);

  if (state == _Flutter.present) {
    editor.update(['flutter', 'assets'], assets);
  } else {
    editor.update(['flutter'], {'assets': assets});
  }

  var result = editor.toString();
  return _handlePlaceholder(pubspecContent, result, assets);
}

enum _Flutter { present, isNull, missing }

_Flutter _flutterState(YamlEditor editor) {
  try {
    final node = editor.parseAt(['flutter']);
    return node.value == null ? _Flutter.isNull : _Flutter.present;
  } catch (_) {
    return _Flutter.missing;
  }
}

final _placeholderRegex = RegExp(
  r'^[ \t]*#[ \t]*To add assets to your (?:application|package)[^\n]*\n'
  r'[ \t]*#[ \t]*assets:[^\n]*\n'
  r'[ \t]*#[^\n]*a_dot_burr\.jpeg[^\n]*\n'
  r'[ \t]*#[^\n]*a_dot_ham\.jpeg[^\n]*\n?',
  multiLine: true,
);

String _handlePlaceholder(String original, String edited, List<String> assets) {
  if (!_placeholderRegex.hasMatch(original)) return edited;

  if (!RegExp(r'^[ \t]*assets:', multiLine: true).hasMatch(original)) {
    final dummy = YamlEditor('assets:\n');
    dummy.update(['assets'], assets);
    final indented = dummy
        .toString()
        .trim()
        .split('\n')
        .map((l) => '  $l')
        .join('\n');
    return original.replaceFirst(_placeholderRegex, '$indented\n');
  }

  return edited.replaceFirst(_placeholderRegex, '');
}
