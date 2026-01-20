# Riverpod Setup Guide

Quick reference for setting up Riverpod in your Flutter projects.

---

## 📦 Package Installation

### Essential Packages (Minimal Setup)

Install these packages to get started with Riverpod:

```bash
flutter pub add flutter_riverpod riverpod_annotation dev:riverpod_generator dev:build_runner
```

**Breakdown:**
- `flutter_riverpod` - Main Riverpod package for Flutter
- `riverpod_annotation` - Annotations for code generation (`@riverpod`)
- `riverpod_generator` - Generates provider code (dev dependency)
- `build_runner` - Runs code generation (dev dependency)

### Full Setup (With Freezed & Linting)

For a complete setup including immutable data classes and linting:

```bash
flutter pub add flutter_riverpod riverpod_annotation freezed_annotation dev:riverpod_generator dev:build_runner dev:freezed dev:riverpod_lint dev:custom_lint
```

**Additional packages:**
- `freezed_annotation` - For immutable data classes with `@freezed`
- `freezed` - Generates immutable classes (dev dependency)
- `riverpod_lint` - Linting rules for Riverpod best practices
- `custom_lint` - Custom lint support

### Optional: Faker for Testing

For generating fake data (like in your tutorial):

```bash
flutter pub add dev:faker
```

---

## 🔨 Build Runner Commands

### Development (Most Common)

Start watch mode - runs continuously and auto-generates on file changes:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

**Shorthand:**
```bash
dart run build_runner watch -d
```

**When to use:** Start this once when you begin your coding session, leave it running in the background.

### One-Time Build

Generate code once and stop:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Shorthand:**
```bash
dart run build_runner build -d
```

**When to use:** Before committing code, in CI/CD pipelines, or when you don't need continuous generation.

### Clean Build

Delete all generated files and rebuild from scratch:

```bash
dart run build_runner clean
dart run build_runner build -d
```

**When to use:** When you have generation errors or want a fresh start.

---

## 🎨 Quality of Life Improvements

### Option 1: Hide Generated Files (VS Code)

Hide `.g.dart` and `.freezed.dart` files from the file explorer.

Create or edit `.vscode/settings.json` in your project root:

```json
{
  "files.exclude": {
    "**/*.g.dart": true,
    "**/*.freezed.dart": true
  }
}
```

**Pros:** Clean file explorer
**Cons:** Files won't appear in search results

### Option 2: Nest Generated Files (VS Code) ⭐ Recommended

Group generated files under their parent files in the explorer.

Create or edit `.vscode/settings.json`:

```json
{
  "explorer.fileNesting.enabled": true,
  "explorer.fileNesting.patterns": {
    "*.dart": "${capture}.g.dart, ${capture}.freezed.dart"
  }
}
```

**Result:**
```
📁 todo_list.notifier.dart
  └─ 📄 todo_list.notifier.g.dart
📁 todo_list.model.dart
  └─ 📄 todo_list.model.freezed.dart
  └─ 📄 todo_list.model.g.dart
```

**Pros:** Files are still accessible but visually organized
**Cons:** None!

### Option 3: Full VS Code Configuration

Combine file nesting with other useful settings:

```json
{
  "explorer.fileNesting.enabled": true,
  "explorer.fileNesting.expand": false,
  "explorer.fileNesting.patterns": {
    "*.dart": "${capture}.g.dart, ${capture}.freezed.dart"
  },
  "dart.previewFlutterUiGuides": true,
  "dart.lineLength": 100,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.rulers": [80, 100]
  }
}
```

---

## 📝 .gitignore Configuration

Generated files **should be committed** to version control, but you might want to add these entries:

```gitignore
# Riverpod build_runner cache
.dart_tool/
build/

# If you choose NOT to commit generated files (not recommended)
# Uncomment these lines:
# *.g.dart
# *.freezed.dart
```

> [!IMPORTANT]
> **Best Practice:** Commit generated files (`.g.dart`, `.freezed.dart`) to Git. This ensures:
> - Other developers can run the app immediately after cloning
> - No build_runner errors on fresh clones
> - Faster CI/CD pipelines

---

## 🚀 Quick Start Workflow

### 1. New Project Setup

```bash
# Create Flutter project
flutter create my_riverpod_app
cd my_riverpod_app

# Install Riverpod packages
flutter pub add flutter_riverpod riverpod_annotation dev:riverpod_generator dev:build_runner

# Optional: Add freezed for immutable models
flutter pub add freezed_annotation dev:freezed

# Configure VS Code (optional)
mkdir .vscode
# Then add settings.json with file nesting config
```

### 2. Daily Development Workflow

```bash
# Terminal 1: Start build_runner watch mode
dart run build_runner watch -d

# Terminal 2: Run your app
flutter run

# Code normally - build_runner auto-regenerates on save
```

### 3. Before Committing

```bash
# Stop watch mode (Ctrl+C)
# Do a clean build
dart run build_runner build -d

# Format code
dart format .

# Commit everything including generated files
git add .
git commit -m "Your commit message"
```

---

## 🔍 Troubleshooting

### Problem: "Conflicting outputs" error

**Solution:**
```bash
dart run build_runner clean
dart run build_runner build -d
```

### Problem: Generated files not updating

**Solution:**
1. Stop watch mode (Ctrl+C)
2. Delete `.dart_tool/` folder
3. Run `dart run build_runner build -d`
4. Restart watch mode

### Problem: Import errors after generation

**Solution:**
Ensure you have the `part` directive in your file:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_file.g.dart'; // ← Must match filename

@riverpod
class MyNotifier extends _$MyNotifier {
  // ...
}
```

---

## 📚 Additional Resources

- [Official Riverpod Docs](https://riverpod.dev)
- [Riverpod Architecture](https://riverpod.dev/docs/concepts/providers)
- [Code Generation Guide](https://riverpod.dev/docs/concepts/about_code_generation)
- [Freezed Package](https://pub.dev/packages/freezed)

---

## 🎯 Quick Command Reference

| Task | Command |
|------|---------|
| **Install Riverpod** | `flutter pub add flutter_riverpod riverpod_annotation dev:riverpod_generator dev:build_runner` |
| **Start watch mode** | `dart run build_runner watch -d` |
| **One-time build** | `dart run build_runner build -d` |
| **Clean & rebuild** | `dart run build_runner clean && dart run build_runner build -d` |
| **Run app** | `flutter run` |
| **Format code** | `dart format .` |

---

> [!TIP]
> **Pro Tip:** Create a VS Code task for build_runner watch mode. Add to `.vscode/tasks.json`:
> ```json
> {
>   "version": "2.0.0",
>   "tasks": [
>     {
>       "label": "watch",
>       "command": "dart",
>       "args": ["run", "build_runner", "watch", "-d"],
>       "type": "shell",
>       "isBackground": true,
>       "problemMatcher": []
>     }
>   ]
> }
> ```
> Then run with `Ctrl+Shift+B` → Select "watch"
