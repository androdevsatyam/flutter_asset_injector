/// A library to automatically scan and inject asset directories into `pubspec.yaml`.
///
/// This library provides the core logic to recursively scan an assets folder
/// and safely add the discovered directories into the flutter assets section
/// of the `pubspec.yaml` file.
library;

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml_edit/yaml_edit.dart';
import 'package:collection/collection.dart';

/// The main entry point to generate assets.
///
/// Scans the given folder (defaulting to `assets` if no [args] are provided),
/// discovers all files efficiently, and updates the existing `pubspec.yaml`
/// while maintaining original formatting.
void generateAssets(List<String> args) {
  String folderName = 'assets';
  if (args.isNotEmpty) {
    folderName = args.first;
  }

  final currentPath = Directory.current.path;
  final buildDirectory = Directory(p.join(currentPath, folderName));

  if (!buildDirectory.existsSync()) {
    print(
      'Error: "$folderName" folder not found in the current directory: $currentPath',
    );
    return;
  }

  // Find all folders inside the specified folder (including the folder itself) that contain at least one file
  final Set<String> assetPaths = {};

  void scanDirectory(Directory dir) {
    bool hasFiles = false;
    for (final entity in dir.listSync()) {
      if (entity is File) {
        final basename = p.basename(entity.path);
        // Ignore hidden files
        if (!basename.startsWith('.')) {
          hasFiles = true;
        }
      } else if (entity is Directory) {
        scanDirectory(entity);
      }
    }

    if (hasFiles) {
      // Normalize path to use forward slashes for pubspec.yaml
      String relativePath = p.relative(dir.path, from: currentPath);
      // Ensure forward slashes
      relativePath = relativePath.replaceAll('\\', '/');
      if (!relativePath.endsWith('/')) {
        relativePath += '/';
      }
      assetPaths.add(relativePath);
    }
  }

  scanDirectory(buildDirectory);

  if (assetPaths.isEmpty) {
    print('No valid files found in "$folderName" folder.');
    return;
  }

  final pubspecFile = File(p.join(currentPath, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found at $currentPath');
    return;
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final yamlEditor = YamlEditor(pubspecContent);

  List<String> finalAssets = [];
  bool hasFlutterSection = false;

  bool flutterIsNull = false;

  try {
    final flutterNode = yamlEditor.parseAt(['flutter']);
    hasFlutterSection = true;
    if (flutterNode.value == null) {
      flutterIsNull = true;
    }

    if (!flutterIsNull) {
      try {
        final assetsNode = yamlEditor.parseAt(['flutter', 'assets']);
        if (assetsNode.value is Iterable) {
          for (var asset in assetsNode.value as Iterable) {
            finalAssets.add(asset.toString());
          }
        }
      } catch (e) {
        // The 'assets' node doesn't exist, which is fine.
      }
    }
  } catch (e) {
    // The 'flutter' node doesn't exist
    hasFlutterSection = false;
  }

  final prefix = folderName.endsWith('/') ? folderName : '$folderName/';
  finalAssets.removeWhere((element) => element.startsWith(prefix));

  finalAssets.addAll(assetPaths);
  finalAssets =
      finalAssets.toSet().toList()
        ..sort((a, b) => compareNatural(a.toLowerCase(), b.toLowerCase()));

  // Fallback YamlEditor if the visual placeholder doesn't exist
  if (hasFlutterSection && !flutterIsNull) {
    yamlEditor.update(['flutter', 'assets'], finalAssets);
  } else {
    yamlEditor.update(['flutter'], {'assets': finalAssets});
  }

  String finalYamlString = yamlEditor.toString();

  // The user specifically wants the assets block to visually replace the flutter placeholder.
  // YamlEditor often alphabetizes new keys which places 'assets' strangely above 'uses-material-design'
  // and separates it from its comments. So we explicitly do a string substitution when possible.
  final placeholderRegex = RegExp(
    r'(^[ \t]*)#[ \t]*To add assets to your (?:application|package)[^\n]*\n[ \t]*#[ \t]*assets:[^\n]*\n[ \t]*#[^\n]*a_dot_burr\.jpeg[^\n]*\n[ \t]*#[^\n]*a_dot_ham\.jpeg[^\n]*\n?',
    multiLine: true,
  );

  var originalPubspecContent = pubspecFile.readAsStringSync();
  if (placeholderRegex.hasMatch(originalPubspecContent)) {
    // Generate a perfectly formatted YAML block using a dummy editor
    final dummyEditor = YamlEditor('assets:\n');
    dummyEditor.update(['assets'], finalAssets);
    final formattedAssets = dummyEditor.toString().trim();
    // Indent it correctly for inside 'flutter:'
    final indentedAssets =
        formattedAssets.split('\n').map((line) => '  $line').join('\n');

    // Make sure we didn't already have a valid assets block somewhere
    // otherwise we might duplicate it.
    if (!RegExp(r'^[ \t]*assets:', multiLine: true).hasMatch(originalPubspecContent)) {
      finalYamlString = originalPubspecContent.replaceFirst(
        placeholderRegex,
        '$indentedAssets\n',
      );
    } else {
      // Just strip the comment if yamlEditor already did its job in the AST
      finalYamlString = finalYamlString.replaceFirst(placeholderRegex, '');
    }
  }

  pubspecFile.writeAsStringSync(finalYamlString);
  print(
    'Successfully updated pubspec.yaml with ${assetPaths.length} paths from "$folderName".',
  );
}
