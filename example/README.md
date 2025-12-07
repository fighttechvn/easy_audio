# Easy Audio Example

Example app demonstrating both Simple API and Advanced API usage.

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## What's Included

### Simple API Demo (Default)

The default example (`lib/main.dart` and `lib/src/simple_example_screen.dart`) demonstrates the **Simple API**:

- ✅ Minimal setup (3 lines in `main.dart`)
- ✅ Uses `SimpleRecordMixin` (only 2 required methods)
- ✅ Uses `SimpleAudioPlayer` widget
- ✅ Clean, easy-to-understand code

**Perfect for:**
- Quick prototyping
- Simple recording needs
- Learning the basics

### Advanced API Demo

The advanced example (`lib/src/advanced_example_screen.dart`) shows the **Advanced API**:

- Full control over BLoC state
- Custom session management
- Language model preparation
- Complex UI interactions

**Perfect for:**
- Production apps with complex requirements
- Custom session handling
- Advanced customization

## Switching Between Examples

To try the Advanced API example, modify `lib/main.dart`:

```dart
// Change this line:
home: const SimpleExampleScreen(),

// To this:
home: const EasyAudioExampleScreen(),
```

And add the import:
```dart
import 'src/advanced_example_screen.dart';
```

## Key Differences

| Feature | Simple API | Advanced API |
|---------|-----------|--------------|
| Setup | 3 lines | 50+ lines |
| Required methods | 2 | 12+ |
| BLoC setup | None | Manual |
| DI setup | None | Required |
| Customization | Limited | Full control |

## Learn More

- [Quick Start Guide](../README.md#quick-start-simple-api)
- [Advanced Documentation](../docs/doc-easy-audio.md)
