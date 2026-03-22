# flutter_asset_injector

[![Pub Version](https://img.shields.io/pub/v/flutter_asset_injector?color=blue&logo=dart)](https://pub.dev/packages/flutter_asset_injector)
[![CI](https://img.shields.io/github/actions/workflow/status/androdevsatyam/flutter_asset_injector/flutter_asset_injector.yml?branch=main&label=CI)](https://github.com/androdevsatyam/flutter_asset_injector/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A Dart CLI that recursively scans your asset directories and injects them into `pubspec.yaml`.

No more manually typing `- assets/images/...` every time you add a folder.

![banner](https://raw.githubusercontent.com/androdevsatyam/flutter_asset_injector/main/assets/banner.png)

---

## Install

```yaml
dev_dependencies:
  flutter_asset_injector: ^1.0.0
```

## Usage

```bash
dart run flutter_asset_injector:generate
```

Custom folder:

```bash
dart run flutter_asset_injector:generate my_custom_folder
```

## Demo

![demo](https://raw.githubusercontent.com/androdevsatyam/flutter_asset_injector/main/assets/example.gif)

## What it does

Given:

```
assets/
  icons/
    home.svg
  images/
    logo.png
    2.0x/
      logo.png
    3.0x/
      logo.png
  translations/
    en.json
```

Running the command updates your `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/images/
    - assets/images/2.0x/
    - assets/images/3.0x/
    - assets/translations/
```

Your existing formatting, comments, fonts, and other Flutter config are preserved.

## Behavior

| Scenario | Result |
|----------|--------|
| Hidden files (`.DS_Store`, `.gitkeep`) | Ignored |
| Hidden directories (`.git/`, `.idea/`) | Skipped |
| Empty directories | Excluded |
| Existing assets from other folders | Preserved |
| Running multiple times | Idempotent |
| Symlinks | Not followed |
| Unreadable directories | Skipped |
| Default placeholder comments (`a_dot_burr`) | Replaced |
| Read-only `pubspec.yaml` | Error with clear message |

## Programmatic usage

```dart
import 'package:flutter_asset_injector/flutter_asset_injector.dart';

try {
  final count = generateAssets(['assets']);
  // count = number of paths injected
} on AssetInjectorException catch (e) {
  // handle error
}
```

## Try it

```bash
git clone https://github.com/androdevsatyam/flutter_asset_injector.git
cd flutter_asset_injector/example
dart run flutter_asset_injector:generate
```

## Contributing

Contributions are welcome. Please open an issue or submit a pull request on [GitHub](https://github.com/androdevsatyam/flutter_asset_injector).

## License

MIT
