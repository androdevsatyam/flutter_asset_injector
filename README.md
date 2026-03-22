# 📁 flutter_asset_injector

[![Pub Version](https://img.shields.io/pub/v/flutter_asset_injector?color=blue&logo=dart)](https://pub.dev/packages/flutter_asset_injector)
![Popularity](https://img.shields.io/pub/popularity/flutter_asset_injector)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> Say goodbye to manually typing `- assets/images/...` in your `pubspec.yaml`. Let a single command do it for you while keeping your file formatting intact!

---

![Banner Placeholder](https://raw.githubusercontent.com/androdevsatyam/flutter_asset_injector/main/assets/banner.png)

----
## 💡 The Motive
In Flutter, defining assets in `pubspec.yaml` can get incredibly tedious when your project scales. Creating a new module feature often means making new asset directories like `assets/icons/home_feature/`, and forgetting to declare them in `pubspec.yaml` leads to frustrating "Asset not found" crashes during runtime. 

Just like how `flutter_native_splash` handles your splash screens, **`flutter_asset_injector`** provides a simple CLI tool that recursively scans your assets folder and accurately injects every necessary directory path right into your `pubspec.yaml`.

## 🎨 Demonstration

![Demonstration GIF Placeholder](https://raw.githubusercontent.com/androdevsatyam/flutter_asset_injector/main/assets/example.gif)

---

## ✨ Features
* **Zero Config Required:** Plug and play. No bloated configuration models required.
* **Recursive Auto-Discovery:** Scans through all nested directories and safely includes only folders that actually contain files.
* **Natural Sorting:** Lists your paths in the exact same Natural Order that your IDE (VS Code / Android Studio) sorts your folder tree.
* **Respects Your Styling:** Uses intelligent AST Yaml injection under the hood to ensure all your original `pubspec.yaml` **formatting, spacing, and comments remain untouched**.

## 🚀 Quick Start

### 1. Add Dependency
Add this to your package's `pubspec.yaml` (under `dev_dependencies`):

```yaml
dev_dependencies:
  flutter_asset_injector: ^1.0.0
```

### 2. Run the Command
Execute the following from your terminal:
```bash
dart run flutter_asset_injector:generate
```

*By default, the script looks for a root folder named `assets`. If you use different naming, just pass it as an argument:*
```bash
dart run flutter_asset_injector:generate my_custom_folder
```

---

## 🛠 Test It Yourself!

Want to see it in action before adding it to your own project? We have a fully configured example project ready for you to playfully test on!

```bash
git clone https://github.com/androdevsatyam/flutter_asset_injector.git
cd flutter_asset_injector/example
dart run flutter_asset_injector:generate
```

**Boom. Assets Loaded.** Open the `example/pubspec.yaml` and watch how flawlessly the assets were injected.

---

## 🤝 Contributing
Contributions are absolutely welcome! Feel free to open an issue or submit a PR on GitHub.

---


## 👨‍💻 Author

Built with ❤️ by [**@androdevsatyam**](https://github.com/androdevsatyam)

If this tool saved you time, consider ⭐ starring the repo.
___
