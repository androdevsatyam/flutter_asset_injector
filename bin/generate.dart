import 'dart:io';
import 'package:flutter_asset_injector/flutter_asset_injector.dart';

void main(List<String> args) {
  try {
    final folderName = args.isNotEmpty ? args.first : 'assets';
    final count = generateAssets(args);
    stderr.writeln(
      'Successfully updated pubspec.yaml with $count paths from "$folderName".',
    );
  } on AssetInjectorException catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
