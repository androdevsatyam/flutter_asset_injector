import 'dart:io';
import 'package:flutter_asset_injector/flutter_asset_injector.dart';

void main() {
  try {
    final count = generateAssets(['assets']);
    stderr.writeln('Injected $count asset paths.');
  } on AssetInjectorException catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
