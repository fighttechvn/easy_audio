# Easy Audio Integration Guide

## Mục lục

1. [Giới thiệu](#1-giới-thiệu)
2. [Kiến trúc](#2-kiến-trúc)
3. [Cài đặt](#3-cài-đặt)
4. [Cấu hình Dependency Injection](#4-cấu-hình-dependency-injection)
5. [Thiết lập Application](#5-thiết-lập-application)
6. [Sử dụng RecordBloc](#6-sử-dụng-recordbloc)
7. [Tích hợp Recording Modal](#7-tích-hợp-recording-modal)
8. [Audio Playback](#8-audio-playback)
9. [Floating Widget & Session Management](#9-floating-widget--session-management)
10. [Xử lý lỗi thường gặp](#10-xử-lý-lỗi-thường-gặp)
11. [Best Practices](#11-best-practices)

---

## 1. Giới thiệu

`easy_audio` là một module Flutter cung cấp các tính năng:

- **Audio Recording**: Ghi âm với speech-to-text
- **Audio Playback**: Phát lại audio với UI controls
- **Session Management**: Quản lý session recording (minimize/restore)
- **Floating Widget**: Widget nổi để điều khiển recording khi minimize
- **Multi-language Support**: Hỗ trợ nhiều ngôn ngữ cho speech-to-text

### Các thành phần chính

| Component | Mô tả |
|-----------|-------|
| `RecordBloc` | Bloc quản lý state cho audio player và recording |
| `RecordUsecase` | Business logic cho audio operations |
| `EasyAudioController` | Controller low-level cho record/playback |
| `RecordModalService` | Service singleton để mở recording modal |
| `RecordSessionManager` | Quản lý session state cho floating widget |
| `RecordFloatingOverlayWidget` | Widget overlay cho floating record button |

---

## 2. Kiến trúc

```
┌─────────────────────────────────────────────────────────────────┐
│                        Application                               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │           RecordFloatingOverlayWidget<T>                    ││
│  │  ┌──────────────────────────────────────────────────────┐  ││
│  │  │              MaterialApp (child)                      │  ││
│  │  │                                                       │  ││
│  │  │   ┌─────────────────────────────────────────────┐    │  ││
│  │  │   │         Screen with Recording                │    │  ││
│  │  │   │                                              │    │  ││
│  │  │   │  ┌────────────────┐  ┌──────────────────┐   │    │  ││
│  │  │   │  │  RecordBloc    │  │  RecordModal     │   │    │  ││
│  │  │   │  │  <T, A>        │  │  (via Service)   │   │    │  ││
│  │  │   │  └────────────────┘  └──────────────────┘   │    │  ││
│  │  │   └─────────────────────────────────────────────┘    │  ││
│  │  └──────────────────────────────────────────────────────┘  ││
│  │                                                             ││
│  │  ┌──────────────────┐                                       ││
│  │  │ FloatingWidget   │ ← Hiển thị khi session minimized      ││
│  │  └──────────────────┘                                       ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### Flow hoạt động

```
User tap Record → Load Languages → Select Language → Prepare Model 
     ↓
Open RecordModal → Start Recording → Speech-to-Text → Save/Cancel
     ↓
(Nếu minimize) → Floating Widget hiển thị → Tap để restore modal
```

---

## 3. Cài đặt

### 3.1 Thêm dependency

```yaml
# pubspec.yaml
dependencies:
  easy_audio:
    path: ../modules/plugins/easy_audio
```

### 3.2 Import

```dart
import 'package:easy_audio/easy_audio.dart';
```

### 3.3 Exports có sẵn từ package

```dart
// Core services
export 'src/core/services/easy_audio_controller.dart';
export 'src/core/services/record_modal_service.dart';
export 'src/core/services/language_history_service.dart';

// Domain
export 'src/domain/entities/record_data.dart';
export 'src/domain/usecase/record_usecase.dart';

// Presentation
export 'src/presentation/shared/record/bloc/record_bloc.dart';
export 'src/presentation/shared/record/entities/record_state_ui.dart';
export 'src/presentation/shared/widgets/record_floating_overlay_widget.dart';
export 'src/presentation/record_modal/record_session_manager.dart';
```

---

## 4. Cấu hình Dependency Injection

### 4.1 Tạo Record Module

```dart
// lib/src/dependency_injection/modules/record_module.dart

import 'package:easy_audio/easy_audio.dart';

// Import các entity của project
import '../../domain/entities/booking/audio_record_info.dart';
import '../../domain/entities/booking/record_info.dart';

@module
abstract class RecordModule {
  @singleton
  RecordBloc<RecordInfo, AudioRecordInfo> recordBloc(
    RecordUsecase recordUsecase,
  ) => RecordBloc<RecordInfo, AudioRecordInfo>(recordUsecase);
}
```

**Giải thích Generic Types:**

- `T` (RecordInfo): Data type cho session (lưu thông tin context như appointmentId)
- `A` (AudioRecordInfo): Data type cho audio item trong list

### 4.2 Định nghĩa Entity Types

```dart
// lib/src/domain/entities/booking/record_info.dart
class RecordInfo {
  final int appointmentId;
  final String appointmentIdEmr;

  const RecordInfo({
    required this.appointmentId,
    required this.appointmentIdEmr,
  });
}

// lib/src/domain/entities/booking/audio_record_info.dart
class AudioRecordInfo {
  final String? id;
  final String? recordLink;
  final String? content;
  final DateTime? createdAt;

  const AudioRecordInfo({
    this.id,
    this.recordLink,
    this.content,
    this.createdAt,
  });
}
```

---

## 5. Thiết lập Application

### 5.1 Thêm BlocProvider vào Application

```dart
// lib/src/app_delegate.dart

import 'package:easy_audio/easy_audio.dart';
import 'domain/entities/booking/audio_record_info.dart';
import 'domain/entities/booking/record_info.dart';

class AppDelegate {
  void run(Map<String, dynamic> env) {
    runZonedGuarded(() async {
      // ... initialization code ...

      final application = Application(
        // ... other parameters ...
        providers: [
          // ... other providers ...
          
          // ⚠️ QUAN TRỌNG: Phải specify đúng generic types!
          BlocProvider<RecordBloc<RecordInfo, AudioRecordInfo>>(
            create: (context) => injector.get(),
          ),
        ],
      );
      
      runApp(application);
    });
  }
}
```

### 5.2 Wrap MaterialApp với FloatingOverlay

```dart
// lib/src/application.dart

import 'package:easy_audio/easy_audio.dart';
import 'domain/entities/booking/record_info.dart';
import 'presentation/booking/customer_record/bloc/upload_record_bloc.dart';

class Application extends StatefulWidget {
  final GlobalKey<NavigatorState> navigationKey;
  // ... other properties ...

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... configuration ...
      builder: (context, child) {
        return RecordFloatingOverlayWidget<RecordInfo>(
          navigatorKey: widget.navigationKey,
          child: child!,
          
          // Callback để so sánh 2 session data
          isSameData: (dataCurrent, data) =>
              dataCurrent.appointmentIdEmr == data.appointmentIdEmr,
          
          // Callback để validate data
          validData: (data) => data.appointmentIdEmr.isNotEmpty,
          
          // Callback khi user save recording từ floating widget
          onDone: (RecordInfo data, String content, File record, String locale) {
            final context = widget.navigationKey.currentContext;
            if (context != null && context.mounted) {
              context.read<UploadRecordBloc>().add(
                UploadRecordSubmitEvent(
                  appointmentIdEmr: data.appointmentIdEmr,
                  appointmentId: data.appointmentId,
                  record: record,
                  locale: locale,
                  content: content,
                ),
              );
            }
          },
        );
      },
    );
  }
}
```

---

## 6. Sử dụng RecordBloc

### 6.1 Truy cập RecordBloc trong Screen

```dart
class _MyScreenState extends State<MyScreen> {
  // Getter để truy cập bloc với đúng type
  RecordBloc<RecordInfo, AudioRecordInfo> get _recordBloc =>
      context.read<RecordBloc<RecordInfo, AudioRecordInfo>>();

  // Getter để truy cập state UI
  RecordStateUI get _recordStateUI => _recordBloc.state.stateUI;

  // Getter để truy cập audio list
  List<AudioRecordInfo> get _audioList =>
      _recordStateUI.audioList.cast<AudioRecordInfo>();

  // Getter để truy cập audio controller
  EasyAudioController get _audioController => _recordBloc.audioController;
}
```

### 6.2 Initialize và Dispose Audio Player

```dart
@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _recordBloc.add(InitAudioPlayerEvent());
  });
}

@override
void dispose() {
  _recordBloc.add(DisposeAudioPlayerEvent());
  super.dispose();
}
```

### 6.3 Load Supported Languages

```dart
void _loadLanguages() {
  if (!_recordStateUI.isLanguageLoaded) {
    _recordBloc.add(
      RecordLoadSupportedLanguagesEvent(
        currentLocale: context.read<AppSettingBloc>().state.stateUI.locale,
        recordAfterLoaded: true, // Tự động record sau khi load xong
      ),
    );
  }
}
```

### 6.4 Prepare Language Model

```dart
void _prepareLanguageModel(String locale) {
  _recordBloc.add(
    RecordPrepareLanguageModelEvent(locale: locale),
  );
}
```

### 6.5 Listen to RecordBloc States

```dart
BlocConsumer<RecordBloc<RecordInfo, AudioRecordInfo>, RecordState>(
  listener: (context, state) {
    if (state is PrepareLanguageModelLoaded) {
      // Language model đã sẵn sàng, bắt đầu record
      _recordBloc.add(RecordingAudioEvent());
      _startRecordAudio();
    } else if (state is RecordLoaded && state.stateUI.recordAfterLoaded) {
      // Reset state và tiếp tục flow
      _recordBloc.add(RecordResetStateEvent());
      _onTapRecord();
    } else if (state is AudioStateUpdated) {
      // Audio state đã thay đổi (playing/stopped)
      final stateUI = state.stateUI;
      // Update UI dựa trên stateUI.isPlaying, stateUI.isOpenPlayer
    }
  },
  builder: (context, state) {
    final isLoading = state is PrepareLanguageModelLoading ||
                      state is RecordLoadingLanguageModel;
    
    return YourWidget(isLoading: isLoading);
  },
);
```

### 6.6 Quản lý Audio List

```dart
// Thêm một audio item
_recordBloc.add(
  AddAudioItemEvent<AudioRecordInfo>(
    AudioRecordInfo(
      createdAt: DateTime.now(),
      content: 'Audio-001',
      recordLink: filePath,
    ),
  ),
);

// Merge nhiều audio items (từ API)
_recordBloc.add(
  MergeAudioItemsEvent<AudioRecordInfo>(
    audioListFromApi,
    isDuplicate: (existing, newItem) =>
        existing.recordLink == newItem.recordLink,
  ),
);

// Clear audio list
_recordBloc.add(ClearAudioListEvent());
```

---

## 7. Tích hợp Recording Modal

### 7.1 Tạo Mixin cho Record Logic

```dart
// lib/src/presentation/booking/customer_record/customer_record_mixin.dart

import 'package:easy_audio/easy_audio.dart';
import 'domain/entities/booking/record_info.dart';

mixin CustomerRecordMixin<T extends StatefulWidget> on State<T> {
  RecordSessionManager get recordSessionManager =>
      RecordSessionManager.instance;

  bool get hasActiveRecordSession => recordSessionManager.hasActiveSession;

  RecordInfo? get currentSessionRecordInfo {
    final data = recordSessionManager.data;
    if (data is RecordInfo) {
      return data;
    }
    return null;
  }

  bool isCurrentSessionForAppointment(String? appointmentIdEmr) {
    return currentSessionRecordInfo?.appointmentIdEmr == appointmentIdEmr;
  }

  bool hasOtherActiveSession(String? appointmentIdEmr) {
    if (!hasActiveRecordSession) return false;
    final existingIdEmr = currentSessionRecordInfo?.appointmentIdEmr;
    if (existingIdEmr == null || existingIdEmr.isEmpty) return false;
    return existingIdEmr != appointmentIdEmr;
  }

  String getSessionLocale(String? fallbackLocale) {
    return recordSessionManager.locale ?? fallbackLocale ?? 'en-US';
  }

  String? get sessionTranscript => recordSessionManager.title;

  Future<bool?> Function(BuildContext)? get sessionOnExitCallback =>
      recordSessionManager.onExit;

  Future<bool?> Function(BuildContext) createDefaultOnExitCallback() {
    return (ct) {
      if (!mounted && !ct.mounted) return Future.value(false);
      final ctDialog = mounted ? context : ct;
      return ctDialog.showStopRecordingConfirmDialog();
    };
  }

  Future<RecordData?> openRecordModalWithSession({
    required String appointmentIdEmr,
    required int appointmentId,
    required String locale,
    String? transcript,
    Future<bool?> Function(BuildContext)? onExit,
    bool restoreFromSession = false,
  }) async {
    final result = await RecordModalService.instance.openModal<RecordInfo>(
      locale: locale,
      data: RecordInfo(
        appointmentId: appointmentId,
        appointmentIdEmr: appointmentIdEmr,
      ),
      transcript: transcript,
      onExit: onExit,
      restoreFromSession: restoreFromSession,
      isSameData: (dataCurrent, data) =>
          dataCurrent.appointmentIdEmr == data.appointmentIdEmr,
      validData: (data) => data.appointmentIdEmr.isNotEmpty,
    );

    if (result != null && RecordModalService.instance.context.mounted) {
      // Upload recording
      RecordModalService.instance.context.read<UploadRecordBloc>().add(
        UploadRecordSubmitEvent(
          appointmentIdEmr: appointmentIdEmr,
          appointmentId: appointmentId,
          record: File(result.url),
          locale: locale,
          content: result.content,
        ),
      );
      
      endRecordSession();
    }

    return result;
  }

  void endRecordSession({bool disposeResources = true}) {
    recordSessionManager.endSession(disposeResources: disposeResources);
  }
}
```

### 7.2 Sử dụng Mixin trong Screen

```dart
class _DetailCustomerRecordScreenState extends State<DetailCustomerRecordScreen>
    with CustomerRecordMixin {
  
  Future<void> _onTapRecord() async {
    final recordState = _recordBloc.state;
    
    // Đang loading, không làm gì
    if (recordState is PrepareLanguageModelLoading ||
        recordState is RecordLoadingLanguageModel) {
      return;
    }

    // Chưa load languages
    if (!_recordStateUI.isLanguageLoaded) {
      _recordBloc.add(
        RecordLoadSupportedLanguagesEvent(
          currentLocale: context.read<AppSettingBloc>().state.stateUI.locale,
          recordAfterLoaded: true,
        ),
      );
      return;
    }

    // Kiểm tra session đang active
    if (hasActiveRecordSession) {
      if (isCurrentSessionForAppointment(widget.appointmentIdEmr)) {
        // Cùng appointment, restore modal
        await _startRecordAudio(restoreFromSession: true);
        return;
      }

      if (hasOtherActiveSession(widget.appointmentIdEmr)) {
        // Khác appointment, hiện dialog
        final shouldRestore = await context.showRecordingInProgressDialog();
        if (shouldRestore == true) {
          await _startRecordAudio(
            restoreFromSession: true,
            useExistingSession: true,
          );
        }
        return;
      }
    }

    // Flow bình thường: select language
    final selectedLocale = await context.startSelectLanguague();
    if (!mounted || selectedLocale == null || selectedLocale.isEmpty) return;

    if (selectedLocale != _recordStateUI.currentLocale) {
      _recordBloc.add(RecordPrepareLanguageModelEvent(locale: selectedLocale));
    } else {
      _recordBloc.add(RecordingAudioEvent());
      await _startRecordAudio();
    }
  }

  Future<void> _startRecordAudio({
    bool restoreFromSession = false,
    bool useExistingSession = false,
  }) async {
    try {
      // Request permissions
      final granted = await context.requestRecordPermissions();
      if (!granted && mounted) {
        context.showPermissionRequiredToast();
        return;
      }

      // Stop current audio
      _playAudio('');

      // Prepare data
      String appointmentIdEmr;
      int appointmentId;
      String locale;
      String? transcript;
      Future<bool?> Function(BuildContext)? onExitCallback;

      final sessionInfo = currentSessionRecordInfo;
      if (useExistingSession && hasActiveRecordSession && sessionInfo != null) {
        appointmentIdEmr = sessionInfo.appointmentIdEmr;
        appointmentId = sessionInfo.appointmentId;
        locale = getSessionLocale(_recordStateUI.currentLocale);
        transcript = sessionTranscript;
        onExitCallback = sessionOnExitCallback;
      } else {
        appointmentIdEmr = widget.appointmentIdEmr!;
        appointmentId = widget.appointmentInfo?.id ?? 0;
        locale = _recordStateUI.currentLocale!;
        transcript = '${_recordStateUI.currentLanguageLabel!} Transcript: ';
        onExitCallback = createDefaultOnExitCallback();
      }

      // Open modal
      final record = await openRecordModalWithSession(
        appointmentIdEmr: appointmentIdEmr,
        appointmentId: appointmentId,
        locale: locale,
        transcript: transcript,
        onExit: onExitCallback,
        restoreFromSession: restoreFromSession,
      );

      if (!mounted || record == null) return;

      // Handle result
      if (record.url.isEmpty) {
        context.showRecordingFilePathEmptySnackBar();
        return;
      }

      await _uploadRecordAudio(record, locale);
      
    } catch (error) {
      if (mounted) {
        context.showRecordingFailedSnackBar(error);
      }
    } finally {
      _recordBloc.add(RecordAudioDoneEvent());
    }
  }
}
```

---

## 8. Audio Playback

### 8.1 Play/Stop Audio

```dart
void _playAudio(String url) {
  // Unfocus keyboard
  final currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus) {
    currentFocus.unfocus();
  }

  // Dispatch event
  _recordBloc.add(PlayAudioEvent(url: url));
}

// Để stop audio, gọi với empty string
_recordBloc.add(PlayAudioEvent(url: ''));

// Hoặc dùng StopAudioEvent
_recordBloc.add(StopAudioEvent());
```

### 8.2 Audio Record Widget với Controller

```dart
AudioRecordWidget(
  url: audioItem.recordLink,
  createdAt: audioItem.createdAt,
  index: index,
  onTap: _playAudio,
  controller: _audioController, // Từ _recordBloc.audioController
)
```

### 8.3 Custom Audio Player Widget

```dart
EasyAudioPlayer(
  controller: _audioController,
  builderSlider: (duration, position, isLoadDone) {
    return Slider(
      value: position?.inMilliseconds.toDouble() ?? 0,
      max: duration?.inMilliseconds.toDouble() ?? 1,
      onChanged: (value) {
        _audioController.seek(Duration(milliseconds: value.toInt()));
      },
    );
  },
  formatTimeSlider: (duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  },
  loading: const CircularProgressIndicator(),
  buttonStop: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(40),
    ),
    child: const Icon(Icons.stop, color: Colors.white),
  ),
)
```

---

## 9. Floating Widget & Session Management

### 9.1 Session States

```
┌─────────────────┐     minimize      ┌─────────────────┐
│                 │ ───────────────▶  │                 │
│  Modal Active   │                   │   Minimized     │
│                 │ ◀───────────────  │ (Floating Show) │
└─────────────────┘     restore       └─────────────────┘
         │                                    │
         │ save/cancel                        │ tap floating
         ▼                                    ▼
┌─────────────────┐               ┌─────────────────┐
│                 │               │                 │
│  Session Ended  │               │  Modal Restored │
│                 │               │                 │
└─────────────────┘               └─────────────────┘
```

### 9.2 RecordSessionManager API

```dart
final sessionManager = RecordSessionManager.instance;

// Kiểm tra session
sessionManager.hasActiveSession   // bool
sessionManager.isMinimized        // bool
sessionManager.isPipelineActive   // bool

// Lấy data
sessionManager.data               // T?
sessionManager.content            // String?
sessionManager.locale             // String?
sessionManager.title              // String?
sessionManager.bloc               // SpeechTextBloc?

// Actions
sessionManager.startSession(bloc: bloc, locale: 'en-US', title: 'Recording');
sessionManager.minimizeSession();
sessionManager.restoreSession();
sessionManager.endSession(disposeResources: true);

// Stream để listen state changes
sessionManager.minimizedStateStream.listen((isMinimized) {
  // Update UI
});
```

---

## 10. Xử lý lỗi thường gặp

### 10.1 Lỗi: `type 'List<X>' is not a subtype of type 'List<Never>'`

**Nguyên nhân**: Generic types không được specify đúng khi khởi tạo `RecordBloc`.

**Giải pháp**:

```dart
// ❌ SAI - không có generic types
RecordBloc(recordUsecase)

// ✅ ĐÚNG - specify đầy đủ generic types
RecordBloc<RecordInfo, AudioRecordInfo>(recordUsecase)
```

### 10.2 Lỗi: `type '(X, X) => bool' is not a subtype of type '((dynamic, dynamic) => bool)?'`

**Nguyên nhân**: Generic type mismatch trong `isDuplicate` callback.

**Giải pháp**: Sử dụng method `mergeAudioItems` của `RecordStateUI` thay vì gọi qua usecase:

```dart
// ❌ SAI
final newAudioList = _recordUsecase.mergeAudioItems(
  currentStateUI.audioList,
  event.items,
  isDuplicate: event.isDuplicate,
);

// ✅ ĐÚNG
final newStateUI = state.stateUI.mergeAudioItems(
  event.items,
  isDuplicate: event.isDuplicate,
);
```

### 10.3 Lỗi: Navigator key not initialized

**Nguyên nhân**: `RecordModalService` chưa được initialize.

**Giải pháp**: Đảm bảo `RecordFloatingOverlayWidget` wrap `MaterialApp` và được khởi tạo với `navigatorKey`.

```dart
RecordFloatingOverlayWidget<RecordInfo>(
  navigatorKey: widget.navigationKey, // ⚠️ Phải truyền đúng key
  child: materialApp,
  // ...
)
```

### 10.4 Lỗi: Bloc closed

**Nguyên nhân**: Cố gắng dispatch event sau khi bloc đã closed.

**Giải pháp**: Kiểm tra `mounted` và bloc state trước khi dispatch:

```dart
if (mounted && !_recordBloc.isClosed) {
  _recordBloc.add(SomeEvent());
}
```

---

## 11. Best Practices

### 11.1 Luôn specify Generic Types

```dart
// Khi khai báo
RecordBloc<RecordInfo, AudioRecordInfo>

// Khi read từ context
context.read<RecordBloc<RecordInfo, AudioRecordInfo>>()

// Khi listen
BlocConsumer<RecordBloc<RecordInfo, AudioRecordInfo>, RecordState>
```

### 11.2 Cleanup Resources

```dart
@override
void dispose() {
  // Luôn dispose audio player khi screen bị dispose
  _recordBloc.add(DisposeAudioPlayerEvent());
  super.dispose();
}
```

### 11.3 Handle Recording States

```dart
// Kiểm tra đủ các states
if (state is PrepareLanguageModelLoading ||
    state is RecordLoadingLanguageModel) {
  // Show loading
}

if (state is PrepareLanguageModelError) {
  // Show error
}

if (state is RecordingAudio) {
  // Recording đang diễn ra
}

if (state is RecordAudioDone) {
  // Recording đã hoàn thành
}
```

### 11.4 Session Management

```dart
// Luôn kiểm tra active session trước khi mở modal mới
if (hasActiveRecordSession) {
  if (isCurrentSessionForAppointment(appointmentId)) {
    // Restore session hiện tại
  } else {
    // Hiện dialog cảnh báo
  }
}
```

### 11.5 Permission Handling

```dart
// Luôn request permissions trước khi record
final granted = await context.requestRecordPermissions();
if (!granted) {
  context.showPermissionRequiredToast();
  return;
}
```

---

## Tài liệu tham khảo

- [Flutter BLoC Documentation](https://bloclibrary.dev)
- [speech_to_text package](https://pub.dev/packages/speech_to_text)
- [record package](https://pub.dev/packages/record)
- [audioplayers package](https://pub.dev/packages/audioplayers)
